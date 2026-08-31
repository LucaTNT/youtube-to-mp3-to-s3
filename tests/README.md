# Tests

This project's scripts (`download.sh`, `entrypoint`) are tested with [Bats-core](https://github.com/bats-core/bats-core).

## Setup

```bash
brew install bats-core   # macOS
# or: sudo apt-get install bats   # Debian/Ubuntu
```

## Fast unit tests (no network)

`download.bats` and `entrypoint.bats` run the real scripts as subprocesses, with `yt-dlp`, `mc`
and `go-cron` replaced by logging stubs in `fixtures/bin`. They check lock handling, env-var
defaults/overrides, the `yt-dlp` invocation, the S3 upload hook, and the pre/post command hooks.

```bash
bats tests/download.bats tests/entrypoint.bats
```

## Smoke test (real network, real yt-dlp)

`smoke.bats` runs `download.sh` for real against a fixed, extremely stable YouTube video ("Me at
the zoo", the first video ever uploaded) and checks that a real, valid mp3 comes out. This is the
test that catches the most common real-world failure: YouTube changes something and `yt-dlp` stops
working. It needs `yt-dlp` installed locally and internet access, so it's not run automatically -
run it manually whenever you want to sanity-check that downloads still work (e.g. before a
release, or when you suspect something broke):

```bash
bats tests/smoke.bats
```
