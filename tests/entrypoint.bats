#!/usr/bin/env bats

setup() {
  ENTRYPOINT="$BATS_TEST_DIRNAME/../entrypoint"
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  TEST_TMP="$(mktemp -d)"
  MOCK_LOG="$TEST_TMP/mock.log"
  export MOCK_LOG
  PATH="$BATS_TEST_DIRNAME/fixtures/bin:$PATH"
  export PATH
  rm -rf /tmp/download.lock
}

teardown() {
  rm -rf /tmp/download.lock
  rm -rf "$TEST_TMP"
}

@test "runs download.sh directly, once, when DOWNLOAD_CRON is unset" {
  unset DOWNLOAD_CRON
  export YOUTUBE_URL="https://example.com/playlist"
  run bash "$ENTRYPOINT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Executing download on startup"* ]]
  # download.sh itself ran (its mocked yt-dlp call is what's logged here)
  grep -qxF -- "$YOUTUBE_URL" "$MOCK_LOG"
}

@test "execs go-cron with the schedule and download.sh when DOWNLOAD_CRON is set" {
  export DOWNLOAD_CRON="0 0 */6 * * *"
  run bash "$ENTRYPOINT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Scheduling download job"* ]]
  grep -qxF -- "$DOWNLOAD_CRON" "$MOCK_LOG"
  grep -qxF -- "bash" "$MOCK_LOG"
  grep -qxF -- "$REPO_ROOT/download.sh" "$MOCK_LOG"
}
