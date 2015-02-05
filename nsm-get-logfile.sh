#!/bin/bash
# Find the file based on the date that is copied from Squert. It should be
# the file containing captured traffic during the time the alert was recorded.
# It requires a date time as arguments, so don't paste inside quotes.
# Add -w | --wireshark to launch the file in wireshark.
# Add -g | --grep to grep the file for a certain text.

DAY=$1
TIME=$2
date -d "$DAY $TIME" > /dev/null 2>&1

function usage()
{
        echo
	echo "Find the capture file created on the date that is copied from Squert."
	echo "The resulting log file should be file containing traffic caputured"
	echo "during the time the alert was recorded."
	echo "It requires a date and time as arguments, so don't paste them inside quotes."
	echo
        echo "Usage: /bin/bash $0 YYYY-MM-DD HH:MM:SS [OPTIONS]"
        echo
        echo Options are:
        echo "  -w|--wireshark  to launch the selected file in wireshark for analysis."
        echo "  -g|--grep \"text to grep\"  to search the selected file for a string."
        echo
}

if [ $? -ne 0 ] || [ "$DAY" == "" ] || [ "$TIME" == "" ]; then
	echo
	echo "Invalid date '$DAY $TIME'"
	echo
	usage
	exit 1
fi

FILE=$(find /nsm/sensor_data/seconion-01-eth1/dailylogs/$DAY/ -newermt "$DAY $TIME" -type f | head -n 1)

for i in "$@"
do
  case $i in
    -w | --wireshark)
       echo "Using wireshark to load" >&2
       echo "$FILE"
       wireshark $FILE &
       exit 0
       ;;
    -g | --grep)
       STRING="$4"
       echo
       echo "Stored pcap files are recognized as binary format."
       echo "Using grep to search for $STRING in"
       echo "$FILE" >&2
       grep "$STRING" $FILE -n > /dev/null 2>&1
       if [ $? -eq 0 ]; then 
          echo "Searched string exists.";
       else 
            echo "Searched string was not found."
       fi
       exit 0
       ;;
    -h | --help)
	usage
	;;
    \?)
	echo "Invalid option: -$OPTARG" >&2
	;;
  esac
done

find /nsm/sensor_data/seconion-01-eth1/dailylogs/$DAY/ -newermt "$DAY $TIME" -type f | head -n 1
