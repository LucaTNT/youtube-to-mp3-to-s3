#!/bin/bash
set -eo pipefail

# Make sure only one instance is running,
# thanks https://askubuntu.com/a/157900
if ! mkdir "/tmp/download.lock"; then
    printf "Failed to acquire lock.\n" >&2
    exit 1
fi

# Internal functions, stolen from https://github.com/djmaze/resticker/blob/master/backup
function run_commands {
	COMMANDS=$1
	while IFS= read -r cmd; do echo $cmd && eval $cmd ; done < <(printf '%s\n' "$COMMANDS")
}

function run_exit_commands {
	set +e
	set +o pipefail
	run_commands "${POST_COMMANDS_EXIT:-}"
    rm -rf "/tmp/download.lock"
}

# Schedule run commands on exit and run pre-run commands
trap run_exit_commands EXIT
run_commands "${PRE_COMMANDS:-}"

# Environment variables
if [[ -z "$YOUTUBE_URL" ]]; then
    echo "You must provide at least the YOUTUBE_URL environment variable" 1>&2
    exit 1
fi

OUTPUT_RENAME_PATTERN=${OUTPUT_RENAME_PATTERN:-"%(upload_date)s_%(title)s.%(ext)s"}
DOWNLOAD_LIMIT=${DOWNLOAD_LIMIT:-"15"}
DOWNLOAD_ARCHIVE_PATH=${DOWNLOAD_ARCHIVE_PATH:-"archive.txt"}

# By default after each download the file gets moved to the provided s3-compatible storage
COMMAND_AFTER_SINGLE_FILE=${COMMAND_AFTER_SINGLE_FILE:-"mc --config-dir /tmp/.mc mv {} s3/$S3_BUCKET/"}

# Setup minio client to upload the file
export MC_HOST_s3="https://$S3_ACCESS_KEY_ID:$S3_SECRET_ACCESS_KEY@$S3_ENDPOINT"

set +e
youtube-dl --playlist-end "$DOWNLOAD_LIMIT" \
    --restrict-filenames \
    --output "$OUTPUT_RENAME_PATTERN" \
    --download-archive="$DOWNLOAD_ARCHIVE_PATH" \
    --extract-audio \
    --audio-format mp3 \
    --exec "$COMMAND_AFTER_SINGLE_FILE" \
    "$YOUTUBE_URL"

if [ $? -ne 0 ]
then
	set -e
	run_commands "${POST_COMMANDS_FAILURE:-}"
	exit
else
	set -e
fi

run_commands "${POST_COMMANDS_SUCCESS:-}"
