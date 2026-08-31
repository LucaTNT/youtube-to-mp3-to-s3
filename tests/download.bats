#!/usr/bin/env bats

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../download.sh"
  TEST_TMP="$(mktemp -d)"
  MOCK_LOG="$TEST_TMP/mock.log"
  export MOCK_LOG
  PATH="$BATS_TEST_DIRNAME/fixtures/bin:$PATH"
  export PATH
  rm -rf /tmp/download.lock
  cd "$TEST_TMP"
}

teardown() {
  rm -rf /tmp/download.lock
  rm -rf "$TEST_TMP"
}

@test "fails when YOUTUBE_URL is not set" {
  unset YOUTUBE_URL
  run bash "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"You must provide at least the YOUTUBE_URL"* ]]
}

@test "fails fast when the lock is already held" {
  mkdir /tmp/download.lock
  export YOUTUBE_URL="https://example.com/playlist"
  run bash "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Failed to acquire lock"* ]]
}

@test "invokes yt-dlp with the default flags" {
  export YOUTUBE_URL="https://example.com/playlist"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -qxF -- "--playlist-end" "$MOCK_LOG"
  grep -qxF -- "15" "$MOCK_LOG"
  grep -qxF -- "--restrict-filenames" "$MOCK_LOG"
  grep -qxF -- "--output" "$MOCK_LOG"
  grep -qxF -- "%(upload_date)s_%(title)s.%(ext)s" "$MOCK_LOG"
  grep -qxF -- "--download-archive=archive.txt" "$MOCK_LOG"
  grep -qxF -- "--extract-audio" "$MOCK_LOG"
  grep -qxF -- "--audio-format" "$MOCK_LOG"
  grep -qxF -- "mp3" "$MOCK_LOG"
  grep -qxF -- "$YOUTUBE_URL" "$MOCK_LOG"
}

@test "honors DOWNLOAD_LIMIT, OUTPUT_RENAME_PATTERN, DOWNLOAD_ARCHIVE_PATH and COMMAND_AFTER_SINGLE_FILE overrides" {
  export YOUTUBE_URL="https://example.com/playlist"
  export DOWNLOAD_LIMIT=3
  export OUTPUT_RENAME_PATTERN="%(id)s.%(ext)s"
  export DOWNLOAD_ARCHIVE_PATH="custom-archive.txt"
  export COMMAND_AFTER_SINGLE_FILE="echo done {}"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -qxF -- "3" "$MOCK_LOG"
  grep -qxF -- "%(id)s.%(ext)s" "$MOCK_LOG"
  grep -qxF -- "--download-archive=custom-archive.txt" "$MOCK_LOG"
  grep -qxF -- "echo done {}" "$MOCK_LOG"
}

@test "exports MC_HOST_s3 built from the S3_* variables" {
  export YOUTUBE_URL="https://example.com/playlist"
  export S3_ENDPOINT="s3.example.com"
  export S3_ACCESS_KEY_ID="AKID123"
  export S3_SECRET_ACCESS_KEY="secret456"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -qxF -- "MC_HOST_s3=https://AKID123:secret456@s3.example.com" "$MOCK_LOG"
}

@test "runs PRE_COMMANDS before the download and POST_COMMANDS_SUCCESS after a successful run" {
  export YOUTUBE_URL="https://example.com/playlist"
  export PRE_COMMANDS="echo pre-command-ran"
  export POST_COMMANDS_SUCCESS="echo post-success-ran"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"pre-command-ran"* ]]
  [[ "$output" == *"post-success-ran"* ]]
  grep -qxF -- "$YOUTUBE_URL" "$MOCK_LOG"
}

@test "runs POST_COMMANDS_FAILURE, not POST_COMMANDS_SUCCESS, when yt-dlp fails" {
  export YOUTUBE_URL="https://example.com/playlist"
  export MOCK_YTDLP_EXIT=1
  export POST_COMMANDS_SUCCESS="echo post-success-ran"
  export POST_COMMANDS_FAILURE="echo post-failure-ran"
  run bash "$SCRIPT"
  [[ "$output" == *"post-failure-ran"* ]]
  [[ "$output" != *"post-success-ran"* ]]
}

@test "always runs POST_COMMANDS_EXIT and releases the lock on success" {
  export YOUTUBE_URL="https://example.com/playlist"
  export POST_COMMANDS_EXIT="echo exit-hook-ran"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"exit-hook-ran"* ]]
  [ ! -d /tmp/download.lock ]
}

@test "always runs POST_COMMANDS_EXIT and releases the lock on failure" {
  export YOUTUBE_URL="https://example.com/playlist"
  export MOCK_YTDLP_EXIT=1
  export POST_COMMANDS_EXIT="echo exit-hook-ran"
  run bash "$SCRIPT"
  [[ "$output" == *"exit-hook-ran"* ]]
  [ ! -d /tmp/download.lock ]
}
