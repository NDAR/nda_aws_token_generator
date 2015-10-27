#!/bin/bash
## NDA AWS Token Generator
## Author: NIMH Data Archives
##         http://ndar.nih.gov
## License: MIT
##          https://opensource.org/licenses/MIT

##############################################################################
#
# Script to retrieve generated AWS Tokens from NIMHDA
#
##############################################################################

echo "Beginning token request..."

show_usage() {
    echo "Usage:"
    echo "generate_token.sh [username] [password] [server]"
}

##############################################################################
# Parse Arguments
##############################################################################
if [ -z "$1" ]; then
    echo "No user specified"
    show_usage
    exit 1;
elif [ -z "$2" ]; then
    echo "No password specified"
    show_usage
    exit 1;
elif [ -z "$3" ]; then
    echo "No server specified"
    show_usage
    exit 1;
fi

username="$1"
password=$(echo -n "$2" | sha1sum | sed 's/ .*//')
server="$3"

##############################################################################
# Make Request
##############################################################################
REQUEST_XML=$(cat <<EOF
<?xml version="1.0" ?>
<S:Envelope xmlns:S="http://schemas.xmlsoap.org/soap/envelope/">
    <S:Body>
        <ns3:UserElement xmlns:ns4="http://dataManagerService"
                         xmlns:ns3="http://gov/nih/ndar/ws/datamanager/server/bean/jaxb"
                         xmlns:ns2="http://dataManager/transfer/model">
            <user>
                <id>0</id>
                <name>${username}</name>
                <password>${password}</password>
                <threshold>0</threshold>
            </user>
        </ns3:UserElement>
    </S:Body>
</S:Envelope>
EOF
)
RESPONSE_XML="$(curl -k -s --request POST -H "Content-Type: text/xml" -H "SOAPAction: \"generateToken\""  -d "$REQUEST_XML" $server)"

##############################################################################
# Handle Response
##############################################################################
ERROR=$(echo $RESPONSE_XML | grep -oP '(?<=<errorMessage>).*(?=</errorMessage>)')
if [ -n "$ERROR" ]; then
    echo "Error requesting token: $ERROR"
    exit 1;
fi

accessKey=$(echo $RESPONSE_XML | grep -oP '(?<=<accessKey>).*(?=</accessKey>)')
secretKey=$(echo $RESPONSE_XML | grep -oP '(?<=<secretKey>).*(?=</secretKey>)')
sessionToken=$(echo $RESPONSE_XML | grep -oP '(?<=<sessionToken>).*(?=</sessionToken>)')
expirationDate=$(echo $RESPONSE_XML | grep -oP '(?<=<expirationDate>).*(?=</expirationDate>)')


##############################################################################
# Write Response
##############################################################################
echo "Access Key:    $accessKey"
echo "Secret Key:    $secretKey"
echo "Session Token: $sessionToken"
echo "Expiration:    $expirationDate"

