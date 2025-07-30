#!/bin/bash

# script to upload backlogged data files to an amazon S3 bucket
# the files come from a folder and have names encoded as path names,
# with '@' as the path separator.

AM_SHARED_FILE=/opt/ampi/ampi_common.sh
if [[ ! -f $AM_SHARED_FILE ]]; then
    echo "Can't find shared code file $AM_SHARED_FILE"
    exit 100
fi
. $AM_SHARED_FILE

get_conf DATA_DIR data.dir
get_conf SECRETS_FILE secrets.file

# try to upload one file; delete on success
function upload() {
    # recode path delimiters
    local file=$1
    local path="${file//@/\/}"
    echo doing aws s3 cp "${file}" "s3://${BUCKET_NAME}/${path}"
    if aws s3 cp "${file}" "s3://${BUCKET_NAME}/${path}" && rm "${file}"; then
	echo upload succeeded
    else
	echo upload failed
    fi
}

# switch to data file folder
if ! cd $DATA_DIR; then
    echo unable to cd to directory $DATA_DIR
    exit 1
fi

# read secrets
if [[ ! -f $SECRETS_FILE ]]; then
    echo missing secrets file: $SECRETS_FILE
    exit 2
fi

. $SECRETS_FILE

if [[ "$BUCKET_NAME" == "" ]]; then
    echo missing BUCKET_NAME from secrets file
    exit 3
fi
if [[ "$AWS_ACCESS_KEY_ID" == "" ]]; then
    echo missing AWS_ACCESS_KEY_ID from secrets file
    exit 4
fi
if [[ "$AWS_SECRET_ACCESS_KEY" == "" ]]; then
    echo missing AWS_SECRET_ACCESS_KEY from secrets file
    exit 5
fi

# Set AWS credentials for use by 'aws' command
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY

while true; do
    # send most recent file ('-t' option to ls)
    #
    # ignore files beginning with "_" to allow growing a file in this
    # # folder (if its name starts with "_"), then renaming to a name
    # # without "_" when finished growing.

    f=`ls -1t | grep -v ^_ | head -1l`
    if [[ $f != "" ]]; then
	upload "$f"
    else
	# wait a bit to prevent spinning while waiting for new files
	sleep 5
    fi
done
