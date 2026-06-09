#!/usr/bin/env bash
# Records the entire test session as one .mov, then trims per-test and converts to GIF.
set -e

PROJECT="DemoApp/StoreKitFlowDemo/StoreKitFlowDemo.xcodeproj"
SCHEME="StoreKitFlowDemo"
SIMULATOR_ID="C903FC78-348E-4564-89CD-0E6FB0C80B8F" # iPhone 17 Pro (Booted)
SCREENSHOTS_DIR="Screenshots"
TMP_DIR="/tmp/storekitflow_recordings"
TEST_TARGET="StoreKitFlowDemoUITests"
TEST_CLASS="StoreKitFlowDemoUITests"
FULL_MOV="$TMP_DIR/full_session.mov"

mkdir -p "$SCREENSHOTS_DIR" "$TMP_DIR"
xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
sleep 2

# Build once
echo "▶ Building for testing..."
xcodebuild build-for-testing \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "id=$SIMULATOR_ID" \
    -quiet
echo "   ✓ Build succeeded"

# Test method -> GIF name (order matters — defines trim sequence)
TEST_METHODS=(
    "testRecordProducts:products"
    "testRecordLogs:logs"
    "testRecordCache:cache"
    "testRecordExplorerSubscription:explorer_subscription"
    "testRecordExplorerProduct:explorer_product"
    "testRecordExplorerStore:explorer_store"
    "testRecordGuide:guide"
)

rm -f "$FULL_MOV"

# Start ONE recording for the whole session
echo ""
echo "▶ Starting full-session recording..."
xcrun simctl io "$SIMULATOR_ID" recordVideo --codec=h264 "$FULL_MOV" &
RECORD_PID=$!
sleep 2

# Run all tests sequentially, capturing timestamps before each
declare -A START_TIMES
SESSION_START=$(date +%s.%N)

for ENTRY in "${TEST_METHODS[@]}"; do
    TEST_METHOD="${ENTRY%%:*}"
    GIF_NAME="${ENTRY##*:}"

    echo "   Running $TEST_METHOD..."
    START_TIMES[$GIF_NAME]=$(python3 -c "print($(date +%s.%N) - $SESSION_START)")

    xcodebuild test-without-building \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "id=$SIMULATOR_ID" \
        -only-testing:"$TEST_TARGET/$TEST_CLASS/$TEST_METHOD" \
        -quiet 2>&1 | grep -E "passed|failed|error:" || true

    END_TIMES[$GIF_NAME]=$(python3 -c "print($(date +%s.%N) - $SESSION_START)")
    echo "   ✓ $GIF_NAME: ${START_TIMES[$GIF_NAME]}s → ${END_TIMES[$GIF_NAME]}s"
done

# Stop recording
echo ""
echo "▶ Stopping recording..."
kill -INT $RECORD_PID 2>/dev/null || true
wait $RECORD_PID 2>/dev/null || true
sleep 10

if [ ! -s "$FULL_MOV" ]; then
    echo "✗ Full session recording is empty. Exiting."
    exit 1
fi

FULL_SIZE=$(du -sh "$FULL_MOV" | cut -f1)
echo "   ✓ Full recording: $FULL_MOV ($FULL_SIZE)"

# Trim and convert each segment to GIF
echo ""
for ENTRY in "${TEST_METHODS[@]}"; do
    TEST_METHOD="${ENTRY%%:*}"
    GIF_NAME="${ENTRY##*:}"
    GIF_FILE="$SCREENSHOTS_DIR/${GIF_NAME}.gif"
    TRIM_MOV="$TMP_DIR/${GIF_NAME}_trim.mov"

    START="${START_TIMES[$GIF_NAME]}"
    END="${END_TIMES[$GIF_NAME]}"
    DURATION=$(python3 -c "print($END - $START)")

    echo "▶ Trimming $GIF_NAME (${START}s → ${END}s, ${DURATION}s)..."
    ffmpeg -ss "$START" -t "$DURATION" -i "$FULL_MOV" \
        -c copy -y "$TRIM_MOV" 2>/dev/null

    echo "   Converting to GIF..."
    ffmpeg -i "$TRIM_MOV" \
        -vf "fps=20,scale=390:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=256[p];[s1][p]paletteuse=dither=bayer" \
        -loop 0 -y "$GIF_FILE" 2>/dev/null

    SIZE_BYTES=$(stat -f%z "$GIF_FILE")
    SIZE=$(du -sh "$GIF_FILE" | cut -f1)

    if [ "$SIZE_BYTES" -gt 5242880 ]; then
        echo "   ⚠ ${SIZE} — re-encoding smaller..."
        ffmpeg -i "$TRIM_MOV" \
            -vf "fps=12,scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer" \
            -loop 0 -y "$GIF_FILE" 2>/dev/null
        SIZE=$(du -sh "$GIF_FILE" | cut -f1)
    fi

    echo "   ✓ $GIF_FILE ($SIZE)"
done

echo ""
echo "✅ Done."
ls -lh "$SCREENSHOTS_DIR"/*.gif 2>/dev/null
