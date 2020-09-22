#!/bin/bash

##List of domain names (separated with spaces).
##Subdomains are also supported, e.g., host.example.com, sub.host.example.com
DOMAINS=("example.com")
##APIKEY obtained from Namesilo:
APIKEY="exampleapikey"

## Do not edit lines below ##

##Saved history pubic IP from last check
IP_FILE="/var/tmp/MyPubIP"

##Time IP last updated or 'No IP change' log message output
IP_TIME="/var/tmp/MyIPTime"

##Temporary path for parsing DNS records from Namesilo
DOMAIN_XML_PATH="/var/tmp/"

##How often to output 'No IP change' log messages
NO_IP_CHANGE_TIME=86400

##Response from Namesilo
RESPONSE="/tmp/namesilo_response.xml"

##Choose randomly which OpenDNS resolver to use
RESOLVER=resolver$(echo $((($RANDOM%4)+1))).opendns.com
##Get the current public IP using DNS
CUR_IP="$(dig +short myip.opendns.com @$RESOLVER)"
ODRC=$?

## Try Google DNS if OpenDNS failed
if [ $ODRC -ne 0 ]; then
    echo "IP Lookup at ${RESOLVER} failed!"
    sleep 5
##Choose randomly which Google resolver to use
    RESOLVER=ns$(echo $((($RANDOM%4)+1))).google.com
##Get the current public IP 
    IPQUOTED=$(dig TXT +short o-o.myaddr.l.google.com @$RESOLVER)
    GORC=$?
## Exit if google failed
    if [ $GORC -ne 0 ]; then
      echo "IP Lookup at ${RESOLVER} failed!"
      exit 1
    fi
    CUR_IP=$(echo $IPQUOTED | awk -F'"' '{ print $2}')
fi

##Check file for previous IP address
if [ -f $IP_FILE ]; then
  KNOWN_IP=$(cat $IP_FILE)
else
  KNOWN_IP=
fi


##See if the IP has changed
if [ "$CUR_IP" != "$KNOWN_IP" ]; then
  echo $CUR_IP > $IP_FILE
  echo "Public IP changed to ${CUR_IP} from ${RESOLVER}"

  ##Update DNS record in Namesilo:
  for FQDN in "${DOMAINS[@]}"
  do
    DOMAIN=$(echo $FQDN | grep -oP '[^.]+\.[^.]+$')
    HOST=$(echo $FQDN | sed 's/\.\?[^.]\+\.[^.]\+$//')
    HOST_WITH_DOT=$(echo $HOST | awk '{if($0!="") print $HOST"."; else print ""}')
    curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=xml&key=$APIKEY&domain=$DOMAIN" > $DOMAIN_XML_PATH$DOMAIN.xml
    RECORD_ID=`xmllint --xpath "//namesilo/reply/resource_record/record_id[../host/text() = '$HOST_WITH_DOT$DOMAIN' ]" $DOMAIN_XML_PATH$DOMAIN.xml | grep -oP '(?<=<record_id>).*?(?=</record_id>)'`
    curl -s "https://www.namesilo.com/api/dnsUpdateRecord?version=1&type=xml&key=$APIKEY&domain=$DOMAIN&rrid=$RECORD_ID&rrhost=$HOST&rrvalue=$CUR_IP&rrttl=3603" > $RESPONSE
    RESPONSE_CODE=`xmllint --xpath "//namesilo/reply/code/text()"  $RESPONSE`
        case $RESPONSE_CODE in
        300)
          date "+%s" > $IP_TIME
          echo "Update success. ${FQDN} IP address is now ${CUR_IP}";;
        280)
          echo "Update aborted. ${FQDN} duplicate record found.";;
        *)
          ## put the old IP back, so that the update will be tried next time
          echo $KNOWN_IP > $IP_FILE
          echo "Update failure. DDNS response code was ${RESPONSE_CODE}!";;
    esac
  done

else
  ## Only log all these events NO_IP_CHANGE_TIME after last update
  [ $(date "+%s") -gt $((($(cat $IP_TIME)+$NO_IP_CHANGE_TIME))) ] &&
    echo "Update unneded. ${FQDN} IP address unchanged from ${RESOLVER}" &&
    date "+%s" > $IP_TIME
fi

exit 0