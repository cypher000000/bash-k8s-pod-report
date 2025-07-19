#!/bin/bash
# Usage: ./k8s-pod-report.sh SERVER
set -euo pipefail

LOG_PATH="/tmp/log/"
LOG_FILE="${LOG_PATH}script_log"

SERVER=${1:-def_server}
DATE=$(date +%d_%m_%Y)

FOLDER_PATH="/tmp/state/"
INPUT_FILE="list.out"
INPUT_FILE_URL="https://raw.githubusercontent.com/GreatMedivack/files/master/list.out"
MAX_RETRIES=3
DELAY=300

FAILED_FILE="${SERVER}_${DATE}_failed.out"
RUNNING_FILE="${SERVER}_${DATE}_running.out"
REPORT_FILE="${SERVER}_${DATE}_report.out"

ARCHIVE_PATH="/tmp/state/archives/"
ARCHIVE_FILE="${ARCHIVE_PATH}${SERVER}_${DATE}.tar.gz"

#0
# start logging in LOG_FILE
mkdir -p "$LOG_PATH"
exec >> "$LOG_FILE" 2>&1
echo "$(date '+%Y-%m-%d %H:%M:%S') Starting script with SERVER = '$SERVER'"

#1
# in FOLDER_PATH download pods state file INPUT_FILE from INPUT_FILE_URL with MAX_RETRIES attempts and DELAY
mkdir -p "$FOLDER_PATH"

for ((i=1; i<=MAX_RETRIES; i++)); do
  if wget -q "$INPUT_FILE_URL" -O "${FOLDER_PATH}${INPUT_FILE}"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') '${FOLDER_PATH}${INPUT_FILE}' successfully downloaded (attempt #$i)"
	break
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S') Attempt # $i failed, retrying in 5 minutes" >&2
    if (( i < MAX_RETRIES )); then
      sleep "$DELAY"
    else
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: All $MAX_RETRIES attempts failed, $INPUT_FILE_URL unavailable" >&2
      exit 1
    fi
  fi
done

#2
# in FOLDER_PATH create FAILED_FILE with list of proken pods and RUNNING_FILE with list of running pods
awk 'NR > 1 && ($3=="Error" || $3=="CrashLoopBackOff") {print $1}' "${FOLDER_PATH}${INPUT_FILE}" \
  | sed -E 's/(-[[:alnum:]]{9,10})?-[[:alnum:]]{5}$//' >| "${FOLDER_PATH}${FAILED_FILE}"
echo "$(date '+%Y-%m-%d %H:%M:%S') '${FOLDER_PATH}${FAILED_FILE}' successfully created"

awk 'NR > 1 && $3=="Running" {print $1}' "${FOLDER_PATH}${INPUT_FILE}" \
  | sed -E 's/(-[[:alnum:]]{9,10})?-[[:alnum:]]{5}$//' >| "${FOLDER_PATH}${RUNNING_FILE}"
echo "$(date '+%Y-%m-%d %H:%M:%S') '${FOLDER_PATH}${RUNNING_FILE}' successfully created"

#3
# in FOLDER_PATH create REPORT_FILE with info
rm -f "${FOLDER_PATH}${REPORT_FILE}"
cat << EOF >| "${FOLDER_PATH}${REPORT_FILE}"
- Working services: $(wc -l < "${FOLDER_PATH}${RUNNING_FILE}")
- Broken services: $(wc -l < "${FOLDER_PATH}${FAILED_FILE}")
- Username: $(whoami)
- Date: $(date +%d/%m/%y)
EOF
chmod 444 "${FOLDER_PATH}${REPORT_FILE}"
echo "$(date '+%Y-%m-%d %H:%M:%S') '${FOLDER_PATH}${REPORT_FILE}' successfully created"

#4
# in ARCHIVE_PATH create ARCHIVE_FILE with all files before
mkdir -p "$ARCHIVE_PATH" 
tar -czf "$ARCHIVE_FILE" -C "$FOLDER_PATH" \
  "$INPUT_FILE" "$FAILED_FILE" "$RUNNING_FILE" "$REPORT_FILE"
echo "$(date '+%Y-%m-%d %H:%M:%S') '$ARCHIVE_FILE' successfully created"

#6
# test ARCHIVE_FILE on errors and integrity
if gzip -t "$ARCHIVE_FILE" && tar -tzf "$ARCHIVE_FILE" >/dev/null; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') '$ARCHIVE_FILE' is ok"
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: Archive '$ARCHIVE_FILE' is broken 1" >&2
  exit 1
fi

if tar xOf "$ARCHIVE_FILE" &> /dev/null; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') All files in '$ARCHIVE_FILE' verified successfully"
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: Archive '$ARCHIVE_FILE' is broken 2" >&2
  exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') '$ARCHIVE_FILE' successfully tested"

#5
# delete all created files in FOLDER_PATH but not the archive/s
rm -rf "${FOLDER_PATH}${INPUT_FILE}" "${FOLDER_PATH}${FAILED_FILE}" "${FOLDER_PATH}${RUNNING_FILE}" "${FOLDER_PATH}${REPORT_FILE}"
echo "$(date '+%Y-%m-%d %H:%M:%S') workfiles successfully deleted"

echo "$(date '+%Y-%m-%d %H:%M:%S') Ending script"
