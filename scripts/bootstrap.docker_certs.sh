#!/usr/bin/env bash

BINARY=docker
if ! [[ ($(type /usr/{,local/}{,s}bin/${BINARY} 2> /dev/null)) || ($(which $BINARY)) ]];then 
    echo 'Docker is not yet installed ... not prepping certs'
    exit
fi

PREFIX=""
FORCE=""
DOCKER_CERT_PATH=/etc/docker
VHOST_CLIENT_CERT_PATH=""
COMMON_NAME=localhost
USAGE="Usage: ${0} --vhost-client-cert-path [/some/directory/on/your/virtual/host]"
while (( "$#" )); do
    if [[ "$1" =~ .*--vhost-client-cert-path.* ]]; then VHOST_CLIENT_CERT_PATH=$2;fi    
    if [[ "$1" =~ .*--sysconfig-file-path.* ]]; then DOCKER_SYS_CONFIG_FILE=$2;fi    
    if [[ "$1" =~ .*--common_name.* ]]; then COMMON_NAME=$2;fi    
    if [[ "$1" =~ .*--force.* ]]; then FORCE="true";fi
    if [[ "$1" =~ .*--dry.* ]]; then PREFIX="echo";fi
    if [[ "$1" =~ .*--help.* ]]; then echo "${USAGE}";exit 0;fi
    shift
done

# Tell bash that it should exit the script if any statement returns a non-true return value.
set -o errexit
# Tell bash to exit your script if you try to use an uninitialised variable
set -o nounset

# =========================================================                                                                                             
# Generate Certs for running TLS enabled docker daemon

# Generate Certificates to use with the docker daemon
# Instructions sourced from http://docs.docker.com/articles/https/

# Get the certificate location, i.e. setting the DOCKER_CERT_PATH variable
OS=$(lsb_release -is 2>/dev/null || cat /etc/redhat-release 2>/dev/null)
if [[ $OS =~ "Ubuntu" ]];then
    DOCKER_SYS_CONFIG_FILE=${DOCKER_SYS_CONFIG_FILE-"/etc/sysconfig/docker"}
    if [[ (-f $DOCKER_SYS_CONFIG_FILE) && ( -z $DOCKER_CERT_PATH ) ]];then
        . $DOCKER_SYS_CONFIG_FILE
    elif [[ "${DOCKER_CERT_PATH}" ]];then
        if [[  ! -d "${DOCKER_CERT_PATH}" ]];then
            $PREFIX mkdir -p "${DOCKER_CERT_PATH}" || (echo "Failed to create ${DOCKER_CERT_PATH}";exit 1)
        fi
    else
        echo "No Docker Cert Path specified, and could not find ${DOCKER_SYS_CONFIG_FILE}"
        echo "Giving up ..."
        exit 1
    fi
fi

if [[ $FORCE ]];then
    if ! $PREFIX sudo rm -rf "${DOCKER_CERT_PATH}/*.pem";then 
        echo "Could not clear out files under ${DOCKER_CERT_PATH}"
        echo "You'll have to do this from the virtual host"
    fi
fi    

# randomString from http://utdream.org/post.cfm/bash-generate-a-random-string
# modified to echo value

function randomString {
        # if a param was passed, it's the length of the string we want
        if [[ -n $1 ]] && [[ "$1" -lt 20 ]]; then
                local myStrLength=$1;
        else
                # otherwise set to default
                local myStrLength=8;
        fi

        local mySeedNumber=$$`date +%N`; # seed will be the pid + nanoseconds
        local myRandomString=$( echo $mySeedNumber | md5sum | md5sum );
        # create our actual random string
        #myRandomResult="${myRandomString:2:myStrLength}"
        echo "${myRandomString:2:myStrLength}"
}

# Get a temporary workspace
dir=`mktemp -d`
$PREFIX cd $dir

# Get a random password for the CA and save it
passfile=tmp.pass
password=$(randomString 10)
echo $password > $passfile

# Generate the CA
$PREFIX openssl genrsa -aes256 -passout file:$passfile -out ca-key.pem 2048
$PREFIX openssl req -new -x509 -passin file:$passfile -days 365 -key ca-key.pem -sha256 -out ca.pem -subj "/C=/ST=/L=/O=/OU=/CN=${COMMON_NAME}"

# Generate Server Key and Sign it
$PREFIX openssl genrsa -out server-key.pem 2048
$PREFIX openssl req -subj "/CN=${COMMON_NAME}" -new -key server-key.pem -out server.csr
# Allow from 127.0.0.1
extipfile=extfile.cnf
echo subjectAltName = IP:127.0.0.1 | tee $extipfile
$PREFIX openssl x509 -req -days 365 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -passin file:$passfile -extfile $extipfile

# Generate the Client Key and Sign it
$PREFIX openssl genrsa -out key.pem 2048
$PREFIX openssl req -subj '/CN=client' -new -key key.pem -out client.csr
extfile=tmp.ext
echo extendedKeyUsage = clientAuth | tee $extfile
$PREFIX openssl x509 -req -days 365 -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out cert.pem -extfile $extfile -passin file:$passfile

# Clean up

# set the cert path as configured in /etc/sysconfig/docker

## Move files into place
$PREFIX sudo mv ca.pem $DOCKER_CERT_PATH
$PREFIX sudo mv server-cert.pem $DOCKER_CERT_PATH
$PREFIX sudo mv server-key.pem $DOCKER_CERT_PATH

# since the default user is vagrant and it can run docker without sudo
CLIENT_SIDE_CERT_PATH=/home/vagrant/.docker

$PREFIX mkdir -p $CLIENT_SIDE_CERT_PATH
$PREFIX sudo cp $DOCKER_CERT_PATH/ca.pem $CLIENT_SIDE_CERT_PATH
$PREFIX yes | mv cert.pem key.pem $CLIENT_SIDE_CERT_PATH

$PREFIX chown vagrant:vagrant $CLIENT_SIDE_CERT_PATH

$PREFIX chmod 0444 $CLIENT_SIDE_CERT_PATH/ca.pem
$PREFIX chmod 0444 $CLIENT_SIDE_CERT_PATH/cert.pem
$PREFIX chmod 0444 $CLIENT_SIDE_CERT_PATH/key.pem
$PREFIX chown vagrant:vagrant $CLIENT_SIDE_CERT_PATH/ca.pem
$PREFIX chown vagrant:vagrant $CLIENT_SIDE_CERT_PATH/cert.pem
$PREFIX chown vagrant:vagrant $CLIENT_SIDE_CERT_PATH/key.pem

$PREFIX sudo chmod -v 0400 $DOCKER_CERT_PATH/ca.pem $DOCKER_CERT_PATH/server-cert.pem $DOCKER_CERT_PATH/server-key.pem

if [[ ( ! -d ${VHOST_CLIENT_CERT_PATH} ) && ($VHOST_CLIENT_CERT_PATH)  ]];then
    if ! mkdir -p ${VHOST_CLIENT_CERT_PATH};then
        echo "WARNING: Could not create the client certs to the VHOST Client Cert Path - ${VHOST_CLIENT_CERT_PATH}"
    fi
fi

if [[ ( -d ${VHOST_CLIENT_CERT_PATH} ) && ($VHOST_CLIENT_CERT_PATH)  ]];then
    if ! sudo cp $CLIENT_SIDE_CERT_PATH/* ${VHOST_CLIENT_CERT_PATH}/;then
        echo "WARNING: Could not copy your client certs to the VHOST Client Cert Path - ${VHOST_CLIENT_CERT_PATH}"
    fi
else
    echo "Looks like you didn't specify a VHOST Client Cert Path or the directory doesn't exist ..."
    echo "This is the value I have derived for this reference: ${VHOST_CLIENT_CERT_PATH-NA}"
fi

## Remove remaining files
cd
$PREFIX echo rm -rf $dir

# ============= end of script for generating the certs for TLS enabled docker daemon===

if [[ $OS =~ "Ubuntu" ]];then
    if [[ -f ${DOCKER_SYS_CONFIG_FILE} ]];then 
        grep -q OPTIONS || echo 'OPTIONS=' | tee ${DOCKER_SYS_CONFIG_FILE}
        $PREFIX sudo sed -i.back '/OPTIONS=*/c\OPTIONS="--selinux-enabled -H tcp://0.0.0.0:2376 -H unix:///var/run/docker.sock --tlscacert=/etc/docker/ca.pem --tlscert=/etc/docker/server-cert.pem --tlskey=/etc/docker/server-key.pem --tlsverify"' ${DOCKER_SYS_CONFIG_FILE}
        $PREFIX sudo systemctl restart docker
    elif [[ -d "${DOCKER_CERT_PATH}" ]];then
        DOCKER_DAEMON_JSON="""{
            \"hosts\": [\"unix:///var/run/docker.sock\", \"tcp://0.0.0.0:2376\"],
            \"tls\": false,
            \"tlscacert\": \"${DOCKER_CERT_PATH}/ca.pem\",
            \"tlscert\": \"${DOCKER_CERT_PATH}/server-cert.pem\",
            \"tlskey\": \"${DOCKER_CERT_PATH}/server-key.pem\",
            \"tlsverify\": false
        }
        """
        $PREFIX sudo systemctl daemon-reload 2>/dev/null
        echo -e "${DOCKER_DAEMON_JSON}" | sudo tee /etc/docker/daemon.json
        DOCKER_SYSTEMD_FILE=$(systemctl status docker | grep systemd | egrep -o '\/.*\.service')
        $PREFIX sudo sed -i.back -e 's/ExecStart=.*/ExecStart=\/usr\/bin\/dockerd/' $DOCKER_SYSTEMD_FILE
        $PREFIX sudo systemctl daemon-reload
        $PREFIX sudo systemctl restart docker
    fi
fi