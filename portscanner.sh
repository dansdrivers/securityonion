#!/bin/bash
# portscan_all.sh - To regularly confirm that no unwated ports are open
# This script will generate numerous alerts on the network monitors. So, the 
# time and date must be well known.
#
RESULT_DIR=$(pwd)/port_scans
SEGMENT=192.168.1.0
MASK=24
IP_ADDRESS=
WIPE_ALL_LOG=n
FLAGS="-Pn" 
NMAP=$(which nmap)
if [ "$?" -ne 0 ]; then
  echo " * Fail! Nmap is required to use this script. Please install nmap." 
  exit 1;
fi

function usage {
  echo
  echo " Scan 1 or all IP addresses in a subnet range for open tcp ports." 
  echo " This script will generate numerous alerts on the network monitors." 
  echo " Alert analysts to the time and date of each run." 
  echo
  echo " Usage $0 [OPTIONS: -i 192.168.3.0 -o ./output_dir ...]" 
  echo
  echo " OPTIONS:" 
  echo "  -i  --ip-address    IP address to scan. (Can be repeated for several hosts.)" 
  echo "  -h  --help          Show this help text." 
  echo "  -m  --mask          Subnet mask to use with the segment option. Default 24" 
  echo "  -o  --output-dir    Where you will write the ouput. Default is " $(pwd)/port_scans
  echo "  -s  --segment       Default is 192.169.1.0" 
  echo "  -u  --udp-too       Include udp scan option for Nmap. (Requires root or sudo)" 
  echo "  -w  --wipe-all-log  Blanks out the ip.add.rr.ess-all-port-scans.txt file(s)." 
  echo
}

TEMP=`getopt -o i:m:o:s:uwh --long ip-address:,mask:,output-dir:,segment:,udp-too,wipe-all-log,help \
             -n $0 -- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 2 ; fi

# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP" 

# Parsing for options
while true; do
  case "$1" in
    -i | --ip-address ) 
       if [ "$IP_ADDRESS" == "" ]; then
         IP_ADDRESS="$2"$'\n'
       else
         IP_ADDRESS+="$2"$'\n' 
       fi
       shift 2 
       ;;
    -h | --help ) usage; exit 0 ;;
    -m | --mask ) MASK=$2; shift 2 ;;
    -o | --output-dir ) RESULT_DIR=$2; shift 2 ;;
    -s | --segment ) SEGEMENT=$2; shift 2 ;;
    -u | --udp-too ) 
       if [ "$EUID" -ne 0 ]
       then 
         echo 
         echo " *Fail! udp port scan requires root privilege. Try again with sudo?" 
         echo
         exit 3
       else
         FLAGS="-T4 -sSU" 
       fi
       shift 
       ;;
    -w | --wipe-all-log ) WIPE_ALL_LOG=y; shift ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

if [ ! -d "$RESULT_DIR" ]; then
  mkdir "$RESULT_DIR" 
  if [ "$?" -eq 1 ]; then
    echo
    echo " * Fail! $RESULT_DIR cannot be created." 
    echo
    exit 4;
  fi
fi

if [ "$IP_ADDRESS" == "" ]; then
  # Collect online ipaddresses
  #
  echo "Nmap to awake hosts, and their ip address can be collected with arp." 
  $NMAP -sn "$SEGMENT"/"$MASK" > /dev/null 2>&1
  echo "arp attempts to realize which hosts were are active." 
  arp -a -n | grep -v incomplete > "$RESULT_DIR"/last-hosts-up-scan.txt
else
  # Use only specific ip address(es)
  #
  printf "%s\n" "$IP_ADDRESS" > "$RESULT_DIR"/last-hosts-up-scan.txt
fi

# Use the ip address(es) in last-hosts-up... to scan for all open ports.
#
for IP in $(cat "$RESULT_DIR"/last-hosts-up-scan.txt | cut -d'(' -f 2 | cut -d')' -f 1)
do
  if [ -f "$RESULT_DIR"/"$IP"-last-port-scan.txt ]; then
    echo " * Conducting port scan on $IP." 
    cp "$RESULT_DIR"/"$IP"-last-port-scan.txt "$RESULT_DIR"/"$IP"-prev-port-scan.txt
  else
    echo " * New host detected at $IP." 
  fi
  $NMAP -p 1-65535 --host-timeout 2m "$FLAGS" "$IP" > "$RESULT_DIR"/"$IP"-last-port-scan.txt
  #
  # Blank out the all port scans file if required.
  #
  if [ "$WIPE_ALL_LOG" == "y" ] && [ -f "$RESULT_DIR"/"$IP"-all-port-scans.txt ]; then
    cat /dev/null > "$RESULT_DIR"/"$IP"-all-port-scans.txt
  fi

  # Copy this current scan to the all scan record.
  cat "$RESULT_DIR"/"$IP"-last-port-scan.txt >> "$RESULT_DIR"/"$IP"-all-port-scans.txt
done

# Check for differences
#
CHANGED=
echo "Comparing the last and previous results to find changed results." 
for IP in $(cat "$RESULT_DIR"/last-hosts-up-scan.txt | cut -d'(' -f 2 | cut -d')' -f 1)
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
fi#!/bin/bash
# portscan_all.sh - To regularly confirm that no unwated ports are open
# This script will generate numerous alerts on the network monitors. So, the 
# time and date must be well known.
#
RESULT_DIR=$(pwd)/port_scans
SEGMENT=192.168.1.0
MASK=24
IP_ADDRESS=
WIPE_ALL_LOG=n
FLAGS="-Pn" 
NMAP=$(which nmap)
if [ "$?" -ne 0 ]; then
  echo " * Fail! Nmap is required to use this script. Please install nmap." 
  exit 1;
fi

function usage {
  echo
  echo " Scan 1 or all IP addresses in a subnet range for open tcp ports." 
  echo " This script will generate numerous alerts on the network monitors." 
  echo " Alert analysts to the time and date of each run." 
  echo
  echo " Usage $0 [OPTIONS: -i 192.168.3.0 -o ./output_dir ...]" 
  echo
  echo " OPTIONS:" 
  echo "  -i  --ip-address    IP address to scan. (Can be repeated for several hosts.)" 
  echo "  -h  --help          Show this help text." 
  echo "  -m  --mask          Subnet mask to use with the segment option. Default 24" 
  echo "  -o  --output-dir    Where you will write the ouput. Default is " $(pwd)/port_scans
  echo "  -s  --segment       Default is 192.169.1.0" 
  echo "  -u  --udp-too       Include udp scan option for Nmap. (Requires root or sudo)" 
  echo "  -w  --wipe-all-log  Blanks out the ip.add.rr.ess-all-port-scans.txt file(s)." 
  echo
}

TEMP=`getopt -o i:m:o:s:uwh --long ip-address:,mask:,output-dir:,segment:,udp-too,wipe-all-log,help \
             -n $0 -- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 2 ; fi

# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP" 

# Parsing for options
while true; do
  case "$1" in
    -i | --ip-address ) 
       if [ "$IP_ADDRESS" == "" ]; then
         IP_ADDRESS="$2"$'\n'
       else
         IP_ADDRESS+="$2"$'\n' 
       fi
       shift 2 
       ;;
    -h | --help ) usage; exit 0 ;;
    -m | --mask ) MASK=$2; shift 2 ;;
    -o | --output-dir ) RESULT_DIR=$2; shift 2 ;;
    -s | --segment ) SEGEMENT=$2; shift 2 ;;
    -u | --udp-too ) 
       if [ "$EUID" -ne 0 ]
       then 
         echo 
         echo " *Fail! udp port scan requires root privilege. Try again with sudo?" 
         echo
         exit 3
       else
         FLAGS="-T4 -sSU" 
       fi
       shift 
       ;;
    -w | --wipe-all-log ) WIPE_ALL_LOG=y; shift ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

if [ ! -d "$RESULT_DIR" ]; then
  mkdir "$RESULT_DIR" 
  if [ "$?" -eq 1 ]; then
    echo
    echo " * Fail! $RESULT_DIR cannot be created." 
    echo
    exit 4;
  fi
fi

if [ "$IP_ADDRESS" == "" ]; then
  # Collect online ipaddresses
  #
  echo "Nmap to awake hosts, and their ip address can be collected with arp." 
  $NMAP -sn "$SEGMENT"/"$MASK" > /dev/null 2>&1
  echo "arp attempts to realize which hosts were are active." 
  arp -a -n | grep -v incomplete > "$RESULT_DIR"/last-hosts-up-scan.txt
else
  # Use only specific ip address(es)
  #
  printf "%s\n" "$IP_ADDRESS" > "$RESULT_DIR"/last-hosts-up-scan.txt
fi

# Use the ip address(es) in last-hosts-up... to scan for all open ports.
#
for IP in $(cat "$RESULT_DIR"/last-hosts-up-scan.txt | cut -d'(' -f 2 | cut -d')' -f 1)
do
  if [ -f "$RESULT_DIR"/"$IP"-last-port-scan.txt ]; then
    echo " * Conducting port scan on $IP." 
    cp "$RESULT_DIR"/"$IP"-last-port-scan.txt "$RESULT_DIR"/"$IP"-prev-port-scan.txt
  else
    echo " * New host detected at $IP." 
  fi
  $NMAP -p 1-65535 --host-timeout 2m "$FLAGS" "$IP" > "$RESULT_DIR"/"$IP"-last-port-scan.txt
  #
  # Blank out the all port scans file if required.
  #
  if [ "$WIPE_ALL_LOG" == "y" ] && [ -f "$RESULT_DIR"/"$IP"-all-port-scans.txt ]; then
    cat /dev/null > "$RESULT_DIR"/"$IP"-all-port-scans.txt
  fi

  # Copy this current scan to the all scan record.
  cat "$RESULT_DIR"/"$IP"-last-port-scan.txt >> "$RESULT_DIR"/"$IP"-all-port-scans.txt
done

# Check for differences
#
CHANGED=
echo "Comparing the last and previous results to find changed results." 
for IP in $(cat "$RESULT_DIR"/last-hosts-up-scan.txt | cut -d'(' -f 2 | cut -d')' -f 1)
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