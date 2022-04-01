The purpose of this thing is to have a recurring `youtube-dl` job monitoring a playlist and download the audio of new uploads, convert it to mp3, then upload it to a S3-compatible storage service.

It uses [yt-dlp](https://github.com/yt-dlp/yt-dlp), a fork of the venerable [youtube-dl](https://youtube-dl.org/) to perform the download, [go-cron](https://github.com/djmaze/go-cron/) to schedule the job, and [Minio Client](https://docs.min.io/docs/minio-client-quickstart-guide.html) to provide the S3 upload functionality (which I'm using with [Backblaze B2](https://www.backblaze.com/b2/cloud-storage.html)).

It can be used in conjunction with [worker-feed-from-bucket](https://github.com/LucaTNT/worker-feed-from-bucket) to generate an RSS feed from the bucket contents, thus creating a podcast out of the download mp3s.

**NOTE:** Even though I am making all this public, this is thought for my own personal use, and might not fit your needs. Feel free to fork it/submit PRs if you think it is appropriate.

# Configuration
Environment variables are used to configure this thing.

* `DOWNLOAD_CRON`: (Docker only) if set, it defines the schedule for the youtube-dl job. The syntax is the same used by cron, with an optional first field which specifies seconds. If unset, the script will run and then exit.
* `OUTPUT_RENAME_PATTERN`: The renaming pattern fed to youtube-dl, it defaults to `%(upload_date)s_%(title)s.%(ext)s`. Check [its documation](https://github.com/ytdl-org/youtube-dl/blob/master/README.md#output-template) for further info.
* `DOWNLOAD_LIMIT`: The maximum number of items of a playlist to download. Defaults to `15`.
* `DOWNLOAD_ARCHIVE_PATH`: The path of the "database" (just a text file) where youtube-dl keeps track of what it has already downloaded. Defaults to archive.txt (in the Docker image that file is in `/workdir`).
* `S3_ENDPOINT`: The S3 endpoint to use (just the hostname, without `https://`). For example, AWS's is `s3.amazonaws.com`, B2's is `s3.us-west-001.backblazeb2.com` or `s3.eu-central-003.backblazeb2.com`, and so forth.
* `S3_ACCESS_KEY_ID`: Your API key ID.
* `S3_SECRET_ACCESS_KEY`: Your API secret.
* `S3_BUCKET`: The name of your bucket.
* `COMMAND_AFTER_SINGLE_FILE`: Which command should be executed after each file has downloaded. Use `{}` to refer to the path of the file. Defaults to `mc --config-dir /tmp/.mc mv {} s3/$S3_BUCKET/`, which moves the mp3 to the S3 bucket defined through the previous variables.
* `PRE_COMMANDS`: (Optional) Commands to be executed before the script starts checking for new videos.
* `POST_COMMANDS_EXIT`: (Optional) Commands to be executed after the download script exits (with or without an error).
* `POST_COMMANDS_FAILURE`: (Optional) Commands to be executed after the download fails.
* `POST_COMMANDS_SUCCESS`: (Optional) Commands to be executed after the download succeeds.

If you wish to ignore the S3 capabilities of this thing just set `COMMAND_AFTER_SINGLE_FILE` to a blank string or whatever you think is appropriate.

# Docker example
`docker run -e YOUTUBE_URL="https://www.youtube.com/playlist?list=S0m3N1cePl4yl1st" -e S3_ENDPOINT=s3.eu-central-003.backblazeb2.com -e S3_ACCESS_KEY_ID=SomeKeyID -e S3_SECRET_ACCESS_KEY=SomeSecret -e S3_BUCKET=YourBucket -e DOWNLOAD_CRON='0 0 */6 * * *' -v $(pwd)/archive.txt:/workdir/archive.txt lucatnt/youtube-to-mp3-to-s3`

This would monitor the given YouTube playlist every 6 hours, download at most 15 videos (default value for `DOWNLOAD_LIMIT`), upload it to B2 and keep track of the download files by mounting archive.txt from the local directory into `/workdir/archive.txt`, which is the script's default.
