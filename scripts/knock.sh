#!/bin/sh

# single ip address or filename input list
IP_ADDR="$1"

knocker() {

if [ -f "$IP_ADDR" ] && [ "$IP_ADDR" = "*.csv" ]; then
    # convert to csv then pipe it to awk
    /bin/sh -c "./scritps/tableReader.pl $IP_ARR" \
        | awk -F'","|^"|"$' '{print $2}' - \
        | sudo nmap -Pn -vvv -sV -oN ./output_file.txt -iL -
else
    sudo nmap -Pn -vvv -sV -oN ./output_file.txt "$IP_ADDR"
fi

}
