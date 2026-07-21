#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/version.env"

MODEL_ID="${1:-parakeet-tdt-0.6b-v3-coreml}"
WARM_SAMPLES="${VACHAVOX_BENCHMARK_WARM_SAMPLES:-3}"
OUTPUT_DIR="${VACHAVOX_BENCHMARK_OUTPUT_DIR:-$ROOT_DIR/Docs/evidence/runs}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUTPUT_PATH="$OUTPUT_DIR/local-inference-$STAMP.json"
TEMP_DIR="$(mktemp -d /private/tmp/vachavox-local-inference.XXXXXX)"
MODEL_REPORT="$TEMP_DIR/model-report.json"
STARTUP_TIME="$TEMP_DIR/startup-time.txt"
INPUT_AUDIO="$TEMP_DIR/vachavox-benchmark-input.aiff"
INPUT_TEXT="VachaVox measures local transcription on this Mac using a generated English speech sample."

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

if ! [[ "$WARM_SAMPLES" =~ ^[1-9][0-9]*$ ]]; then
  echo "VACHAVOX_BENCHMARK_WARM_SAMPLES must be a positive integer." >&2
  exit 2
fi

mkdir -p "$OUTPUT_DIR"

echo "Generating the benchmark audio fixture with macOS speech synthesis..."
say -o "$INPUT_AUDIO" "$INPUT_TEXT"

echo "Building the current SwiftPM executable..."
swift build -c debug --product "$PRODUCT_NAME"
BIN_DIR="$(swift build -c debug --show-bin-path)"
EXECUTABLE_PATH="$BIN_DIR/$PRODUCT_NAME"

echo "Measuring app process launch through applicationDidFinishLaunching..."
/usr/bin/time -l env VACHAVOX_EVIDENCE_STARTUP_PROBE=1 "$EXECUTABLE_PATH" >/dev/null 2>"$STARTUP_TIME"
STARTUP_SECONDS="$(awk '$2 == "real" { print $1; exit }' "$STARTUP_TIME")"
STARTUP_USER_SECONDS="$(awk '$2 == "real" { print $3; exit }' "$STARTUP_TIME")"
STARTUP_SYSTEM_SECONDS="$(awk '$2 == "real" { print $5; exit }' "$STARTUP_TIME")"
STARTUP_MAX_RSS_BYTES="$(awk '$2 == "maximum" && $3 == "resident" { print $1; exit }' "$STARTUP_TIME")"
STARTUP_PEAK_MEMORY_BYTES="$(awk '$2 == "peak" && $3 == "memory" { print $1; exit }' "$STARTUP_TIME")"
if [[ -z "$STARTUP_SECONDS" ]]; then
  echo "Could not parse startup timing from $STARTUP_TIME" >&2
  exit 1
fi

echo "Measuring local model preparation and file transcription for $MODEL_ID..."
VACHAVOX_BENCHMARK_MODEL_ID="$MODEL_ID" \
VACHAVOX_BENCHMARK_AUDIO_FILE="$INPUT_AUDIO" \
VACHAVOX_BENCHMARK_OUTPUT="$MODEL_REPORT" \
VACHAVOX_BENCHMARK_WARM_SAMPLES="$WARM_SAMPLES" \
VACHAVOX_BENCHMARK_INPUT_SOURCE="macOS say-generated English speech: $INPUT_TEXT" \
swift test --filter LocalInferenceBenchmarkTests/testConfiguredLocalInferenceMeasurement

GIT_COMMIT="$(git rev-parse HEAD)"
GIT_SHORT_COMMIT="$(git rev-parse --short HEAD)"
if [[ -n "$(git status --porcelain)" ]]; then
  GIT_WORKTREE_STATE="dirty"
else
  GIT_WORKTREE_STATE="clean"
fi
MACOS_VERSION="$(sw_vers -productVersion)"
MACOS_BUILD="$(sw_vers -buildVersion)"
HARDWARE_MODEL="$(sysctl -n hw.model 2>/dev/null || echo unknown)"
CHIP="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo unknown)"
MEMORY_BYTES="$(sysctl -n hw.memsize 2>/dev/null || echo unknown)"

jq -n \
  --arg captured_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg app_version "$MARKETING_VERSION" \
  --arg build_number "$BUILD_NUMBER" \
  --arg git_commit "$GIT_COMMIT" \
  --arg git_short_commit "$GIT_SHORT_COMMIT" \
  --arg git_worktree_state "$GIT_WORKTREE_STATE" \
  --arg macos_version "$MACOS_VERSION" \
  --arg macos_build "$MACOS_BUILD" \
  --arg hardware_model "$HARDWARE_MODEL" \
  --arg chip "$CHIP" \
  --arg memory_bytes "$MEMORY_BYTES" \
  --argjson startup_seconds "$STARTUP_SECONDS" \
  --argjson startup_user_seconds "$STARTUP_USER_SECONDS" \
  --argjson startup_system_seconds "$STARTUP_SYSTEM_SECONDS" \
  --argjson startup_max_rss_bytes "$STARTUP_MAX_RSS_BYTES" \
  --argjson startup_peak_memory_bytes "$STARTUP_PEAK_MEMORY_BYTES" \
  --slurpfile model_report "$MODEL_REPORT" \
  '{
    schema_version: 1,
    captured_at_utc: $captured_at,
    build: {
      app_version: $app_version,
      build_number: $build_number,
      git_commit: $git_commit,
      git_short_commit: $git_short_commit,
      git_worktree_state: $git_worktree_state
    },
    device: {
      hardware_model: $hardware_model,
      chip: $chip,
      memory_bytes: $memory_bytes,
      macos_version: $macos_version,
      macos_build: $macos_build
    },
    app_startup: {
      name: "process_launch_through_applicationDidFinishLaunching",
      state: "Fresh process; model loading is intentionally excluded and measured separately.",
      sample_count: 1,
      seconds: [$startup_seconds],
      median_seconds: $startup_seconds,
      process_resources: {
        scope: "VachaVox startup probe process only; not model-inference memory.",
        user_cpu_seconds: $startup_user_seconds,
        system_cpu_seconds: $startup_system_seconds,
        maximum_resident_set_size_bytes: $startup_max_rss_bytes,
        peak_memory_footprint_bytes: $startup_peak_memory_bytes
      }
    },
    model_inference: $model_report[0]
  }' > "$OUTPUT_PATH"

echo "Wrote machine-specific evidence: $OUTPUT_PATH"
