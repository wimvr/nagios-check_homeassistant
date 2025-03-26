#!/bin/bash

# Author: Wim van Ravesteijn
# Description: Nagios plugin to check Home Assistant via Observer page
# Website: https://github.com/wimvr/nagios-check_homeassistant

VERSION="0.2"

HOST=''
PORT=4357
TIMEOUT=8

STATUS_OK=0
STATUS_WARNING=1
STATUS_CRITICAL=2
STATUS_UNKNOWN=3

function prereq() {
[[ ! -x $(command -v "$1") ]] && { echo "$1 is required"; exit $STATUS_UNKNOWN; }
}

function usage {
	echo "Usage:"
	echo ""
	echo "	$0 -H <hostname> [-p <port>]"
	echo ""
	echo "Options:"
	echo "-H hostname"
	echo "  Host name where Home Assistant runs"
	echo "-p port"
	echo "  Port number (default: 4357)"
	echo "-t timeout"
	echo "  Timeout in seconds when requesting status page (default: 5)"
	echo "-h"
	echo "  Print detailed help"
	echo "-V"
	echo "  Print version"
}

while getopts "H:p:t:hV" args; do
	case $args in
		H) HOST=$OPTARG ;;
		p) PORT=$OPTARG ;;
		t) TIMEOUT=$OPTARG ;;
		V)
			echo "$(basename "$0") version ${VERSION}"
			exit $STATUS_UNKNOWN
			;;
		*)
			usage
			exit $STATUS_UNKNOWN
			;;
	esac
done

if [ -z "$HOST" ]; then
	usage
	echo ""
	echo "Missing -H option"
	exit $STATUS_UNKNOWN
fi
re='^[0-9]+$'
if ! [[ $PORT =~ $re ]]; then
	usage
	echo ""
	echo "Missing or invalid -p option"
	exit $STATUS_UNKNOWN
fi
if ! [[ $TIMEOUT =~ $re ]]; then
	usage
	echo ""
	echo "Missing or invalid -t option"
	exit $STATUS_UNKNOWN
fi

prereq xmllint

PAGE=$(wget -O - --quiet --timeout=$TIMEOUT http://${HOST}:${PORT}/)
if [ $? -ne 0 ]; then
	echo "CRITICAL: No response received while requesting status"
	exit $STATUS_CRITICAL
fi

if [ "$(echo $PAGE | xmllint --html --xpath '//table/tr[1]/td[1]/text()' -)" == " Supervisor: " ]; then
	if [ "$(echo $PAGE | xmllint --html --xpath '//table/tr[1]/td[2]/text()' -)" != " Connected " ]; then
		echo "CRITICAL: Supervisor not connected"
		exit $STATUS_CRITICAL
	fi
else
	echo "UNKNOWN: Unrecognised observer page"
	exit $STATUS_UNKNOWN
fi

if [ "$(echo $PAGE | xmllint --html --xpath '//table/tr[3]/td[1]/text()' -)" == " Health: " ]; then
	if [ "$(echo $PAGE | xmllint --html --xpath '//table/tr[3]/td[2]/text()' -)" != " Healthy " ]; then
		echo "CRITICAL: Home Assistant not healthy"
		exit $STATUS_CRITICAL
	fi
else
	echo "UNKNOWN: Unrecognised observer page"
	exit $STATUS_UNKNOWN
fi

if [ "$(echo $PAGE | xmllint --html --xpath '//table/tr[2]/td[1]/text()' -)" == " Support: " ]; then
	if [ "$(echo $PAGE | xmllint --html --xpath '//table/tr[2]/td[2]/text()' -)" != " Supported " ]; then
		echo "WARNING: Home Assistant is healthy but not supported"
		exit $STATUS_WARNING
	fi
else
	echo "UNKNOWN: Unrecognised observer page"
	exit $STATUS_UNKNOWN
fi

echo "OK: Observer reports Home Assistant up and running"
exit $STATUS_OK
