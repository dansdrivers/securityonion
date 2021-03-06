#!/bin/bash
# portscan_review.sh - To regularly confirm that no unwanted ports are open.
# This script examines the files generated by portscanner.sh.
#
RESULT_DIR=/home/$(whoami)/port_scans

# Check for differences
#
CHANGED=
echo "Comparing the last and previous scan results to find changes." 
echo
for IP in $(find "$RESULT_DIR"  -type f -name *-last-port-scan.txt -print | cut -d'/' -f 5 | cut -d'-' -f 1)
do
  grep -q tcp "$RESULT_DIR"/"$IP"-last-port-scan.txt 
  if [ "$?" -eq 1 ]; then
    echo " * No ports in $RESULT_DIR/$IP-last-port-scan.txt";
    continue;
  fi

  if [ -f "$RESULT_DIR"/"$IP"-prev-port-scan.txt ] && [ -f "$RESULT_DIR"/"$IP"-last-port-scan.txt ]; then
    LAST=$(cat "$RESULT_DIR"/"$IP"-last-port-scan.txt | grep tcp | sort)
    PREV=$(cat "$RESULT_DIR"/"$IP"-prev-port-scan.txt | grep tcp | sort)
    diff -q <(echo "$PREV") <(echo "$LAST") > /dev/null 
    if [ "$?" -eq 1 ]; then
      CHANGED+=" * diff $RESULT_DIR/$IP-prev-port-scan.txt $RESULT_DIR/$IP-last-port-scan.txt" 
    fi
  fi
done

if [ "$CHANGED" == "" ]; then
  echo
  echo "No port configurations have changed since the last scan." 
else
  echo 
  echo "Changes have happened. Try diff to examine following" 
  echo "$CHANGED" 
fi