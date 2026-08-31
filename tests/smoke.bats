#!/usr/bin/env bats
# Real, network-hitting smoke test. Not part of the fast test suite: run it manually
# (or periodically) to check that yt-dlp can still actually download from YouTube -
# that's the failure mode mocked tests can never catch.

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../download.sh"
  TEST_TMP="$(mktemp -d)"
  rm -rf /tmp/download.lock
  cd "$TEST_TMP"
}

teardown() {
  rm -rf /tmp/download.lock
  rm -rf "$TEST_TMP"
}

@test "downloads a real, known-stable YouTube video and produces a valid mp3" {
  if ! command -v yt-dlp >/dev/null 2>&1; then
    skip "yt-dlp is not installed locally (pip install yt-dlp / brew install yt-dlp)"
  fi

  # "Me at the zoo" - the first video ever uploaded to YouTube, 19s, effectively permanent.
  export YOUTUBE_URL="https://www.youtube.com/watch?v=jNQXAC9IVRw"
  export DOWNLOAD_LIMIT=1
  export OUTPUT_RENAME_PATTERN="%(id)s.%(ext)s"
  export DOWNLOAD_ARCHIVE_PATH="$TEST_TMP/archive.txt"
  export COMMAND_AFTER_SINGLE_FILE="true" # skip the real S3 upload, no credentials needed

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  mp3_files=("$TEST_TMP"/*.mp3)
  [ -e "${mp3_files[0]}" ]
  [ "${#mp3_files[@]}" -eq 1 ]

  # catches a truncated/corrupt extraction that still exited 0
  mp3_size=$(wc -c < "${mp3_files[0]}")
  [ "$mp3_size" -gt 10000 ]

  file "${mp3_files[0]}" | grep -qi audio
}
