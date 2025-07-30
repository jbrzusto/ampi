#!/bin/bash

# capture and upload audio from an audiomoth
#
# called as
#
#   ampi_capture.sh DEVNO-SERIAL
#
# where
#
#    - DEVNO is the kernel device number, which depends on plugging and
#    enumeration order; this number is needed for referring to the
#    audiomoth in the ALSA framework (e.g. "hw:CARD=2,DEV=0" for DEVNO=2)
#
#    - RRRR is the zero-padded sampling rate, in kHz; e.g. 0032
#
#    - SERIAL is a 16-digit hex serial number for the audiomoth

AM_SHARED_FILE=/opt/ampi/ampi_common.sh
if [[ ! -f $AM_SHARED_FILE ]]; then
    echo "Can't find shared code file $AM_SHARED_FILE"
    exit 100
fi
. $AM_SHARED_FILE

# Function to record audio
record_audio() {
    # (re-)read config items related to recording
    get_conf INPUT_SAMPLE_RATE input.sample.rate
    get_conf OUTPUT_SAMPLE_RATE output.sample.rate
    get_conf SEEK_POINTS seek.points
    get_conf LATITUDE latitude
    get_conf LONGITUDE longitude

    local ts=$1
    # formatted timestamp, in UTC
    tsf=$(date --utc +"%Y%m%d_%H%M%S" -d@$ts)
    local year=${tsf:0:4}
    local month=${tsf:4:2}
    local day=${tsf:6:2}
    ## only use last 4 characters of microphone serial number in filename
    local base_file="${SITENAME}_${tsf}.flac"
    local s3_path="${SITENAME}/${year}/${month}/${day}/${base_file}"
    ## replace path separators with "@"
    local output_file="${s3_path//\//@}"
    ## file to write to actually until complete, which will then be renamed to $output_file
    local wipo_file="_${output_file}"
    # Record audio, resampling and compressing to flac;
    # record to output_file prefixed with "_" and stream raw (resampmled but un-flacced) audio to
    # the appropriate UDP port
    echo starting recording from $DEVICE_NAME
    ln -s -f record $DEVICE_DIR/state
    ln -s -f $(( $ts + $RECORDING_DURATION )) $DEVICE_DIR/until
    ffmpeg -loglevel error -t $RECORDING_DURATION -f alsa -channels 1 -i hw:$DEVICE_NUM -ar $OUTPUT_SAMPLE_RATE -filter_complex "asplit=2[c1][c2]" -map "[c1]" "${wipo_file}" -map "[c2]" -f s16le -ar 22050 -acodec pcm_s16le -flush_packets 1 -reuse 1 -connect 0 udp://127.0.0.1:$AUDIO_STREAM_PORT
    rc=$?
    if [[ $rc == 0 || $rc == 255 ]]; then
	# add seek points and metadata
	metaflac --remove-all-tags \
		 --preserve-modtime \
		 --add-seekpoint $SEEK_POINTS \
		 --set-tag "lat=$LATITUDE" \
		 --set-tag "long=$LONGITUDE" \
		 --set-tag "am_serno=$DEVICE_SERIAL" \
		 --set-tag "pi_serno=$PI_SERNO" \
		 "${wipo_file}"
	echo finished recording "${output_file}"
	# drop the leading underscore so that the uploader knows this file is complete
	mv "${wipo_file}" "${output_file}"
    else
	echo error trying to record "${output_file}"
    fi
    return $rc
}

# Check for required arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <sound_card_number>-<serial_number>"
    exit 1
fi

get_conf SITENAME_FILE sitename.file

# Read site name from the specified location
if [[ ! -f "$SITENAME_FILE" ]]; then
    echo "error: sitename file $SITENAME_FILE not found."
    exit 1
fi

read SITENAME < $SITENAME_FILE

# Change underscores to hyphens
SITENAME=${SITENAME//_/-}

# read configured parameters
get_conf INPUT_SAMPLE_RATE input.sample.rate
get_conf RECORDING_DURATION recording.duration
get_conf OUTPUT_SAMPLE_RATE output.sample.rate
get_conf SEEK_POINTS seek.points
get_conf RECORDING_SPACING recording.spacing
get_conf AUDIO_STREAM_BASE_PORT audio.stream.base.port
get_conf DATA_DIR data.dir

DEVICE_NUM=${1//-*/}
DEVICE_SERIAL=${1//*-/}
DEVICE_NAME="hw:CARD=$DEVICE_NUM,DEV=0"
DEVICE_DIR=$AM_DEV_DIR/$DEVICE_SERIAL
AUDIO_STREAM_PORT=$(( $AUDIO_STREAM_BASE_PORT + $DEVICE_NUM ))
PI_SERNO=`cat /proc/cpuinfo | grep ^[[:space:]]*Serial`
PI_SERNO=${PI_SERNO/*: /}

# switch to data file dir
if ! cd "${DATA_DIR}"; then
   echo unable to switch to directory "${DATA_DIR}"
   exit 1
fi

# lag is how much time gets eaten by control logic, in ms
# this is removed from sleep time to reduce long-term sliding of
# the recording window.  The lag was estimated from the
# drift in file timestamps over ~ 1.5 hrs
lag=21

# Main loop
while true; do
    # read recording-related configuration
    get_conf RECORDING_DURATION recording.duration
    get_conf RECORDING_SPACING recording.spacing

    # update am config from database parameters, in case they've changed
    # if changed, the device will be re-enumerated, so we quit
    if ! set_am_mode; then
	echo Audiomoth config changed - quitting capture.
	exit 1
    fi
    # get current time in unix timestamp form
    ts=$(date +%s)
    if ! record_audio $ts; then
	exit 1
    fi

    # determine how long to wait before starting the next recording
    now=$(date +%s)
    until=$(( $ts + $RECORDING_SPACING + $RECORDING_DURATION ))
    left=$(( $until - $now ))
    if [[ $left -gt 0 ]]; then
	ln -s -f sleep $DEVICE_DIR/state
	ln -s -f $until $DEVICE_DIR/until
	# make fractional adjustment to sleep time to counter lag of other commands
	printf -v deci "%03d" $(( 1000 - lag ))
	if ! sleep $(( $left - 1 )).$deci; then
	    exit 1
	fi
    fi
done
