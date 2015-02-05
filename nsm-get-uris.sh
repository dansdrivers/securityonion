#!/bin/bash
# Harvest the known IP addresses, server and URI's accessed from the pcap files.
function usage {
  echo
  echo " Scrape some IP addresses, server and URI's accessed from the pcap files."
  echo
  echo " Usage $0 [OPTIONS: -d YYYY-MM-DD -o ./output_dir ...]"
  echo
  echo " OPTIONS:"
  echo "  -d  --date          Date for which to gather data."
  echo "  -f  --fake-run      Show only the files that will be read/skipped."
  echo "  -h  --help          Show this help text."
  echo "  -n  --hostname      Hostname of the sensor to search in the logs."
  echo "  -o  --output-dir    Where you will write the ouput. Default is ./ for"
  echo "                      standard user and /nsm/..../YYYY-MM-DD if root."
  echo "  -w  --wipe-existing Delete and recreate a file if it has been harvested."
  echo
}

TEMP=`getopt -o d:o:whf --long date:,output-dir:,wipe-existing,help,fake-run \
             -n $0 -- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP"

# Defaults
NSMLOGDATE=
OUTPUT_DIR=
WIPE_EXISTING=n
FAKE_RUN=n
HOSTNAME=$(hostname)
INTERFACE=eth1

# Parsing for options
while true; do
  case "$1" in
    -d | --date ) NSMLOGDATE=$2; shift 2; ;;
    -f | --fake-run ) FAKE_RUN=y; shift; ;;
    -h | --help ) usage; exit 0; ;;
    -i | --interface ) INTERFACE=$2; shift 2; ;;
    -n | --hostname ) HOSTNAME=$2; shift 2; ;;
    -o | --output-dir ) OUTPUT_DIR=$2; shift 2; ;;
    -w | --wipe-existing ) WIPE_EXISTING=y; shift; ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

NSMLOGDIR=/nsm/sensor_data/"$HOSTNAME"-"$INTERFACE"/dailylogs

function parse_files(){
  #make a file to hold the output
  if [ "$OUTPUT_DIR" == "" ]; then
    if [ $EUID -ne 0 ]; then
      OUTPUT_DIR="."
    else
      OUTPUT_DIR="${NSMLOGDIR}"/"${NSMLOGDATE}"
    fi
  fi

  OUTPUTFILE="$OUTPUT_DIR"/"http_uri_files_$NSMLOGDATE.txt"

  # If the file exists, skip it, unless overwrite options is set.
  if [ -f "$OUTPUTFILE" ] && [ "$WIPE_EXISTING" == "y" ] ; then
    rm -f $OUTPUTFILE
  fi

  # Create a scrape of uri's other than "/" recorded in the pcap files.
  if [ ! -f "$OUTPUTFILE" ]; then
    echo "Reading input pcap files from ${NSMLOGDIR}"/"${NSMLOGDATE}"/
    if [ "$FAKE_RUN" == "n" ]; then
      cat /dev/null > "${OUTPUTFILE}"
    fi
    for file in "${NSMLOGDIR}"/"${NSMLOGDATE}"/*; do
      if [ "$FAKE_RUN" == "y" ]; then
        echo "FAKE_RUN: $file"
      else
        echo " * $file"
       [ -f "${file}" ] || continue # if not a file, skip
        #do_stuff
          tshark  -R "http.response or http.request and http.request.uri!=\"/\"" \
          -T fields \
          -E separator="|" -e ip.src -e ip.dst -e http.host -e http.request.uri \
          -r "${file}" >> "${OUTPUTFILE}"
      fi
    done
  else
    echo "Skipping $NSMLOGDIR/$NSMLOGDATE. Output file exists. Use -w --wipe-existing to overwrite it."
  fi
}

if [ "$NSMLOGDATE" == "" ]; then
  for path in $NSMLOGDIR/*; do
    [ -d "${path}" ] || continue # if not a directory, skip
    dirname="$(basename "${path}")"
    NSMLOGDATE="${dirname}"
    parse_files
  done
  echo "Done. Results written to $OUTPUT_DIR/http_uri_files_YYYY-MM-DD.txt"
else
  parse_files
  echo
  echo "Done. Try to find stuff like so:"
  echo
  echo "grep -E '\.(exe|dll)$' $OUTPUT_DIR/http_uri_files_$NSMLOGDATE.txt"
fi
