#!/bin/bash



echo "Building client config for --> "${1}" <-- !"
echo "Press Enter to start"
echo "or STRG+c to cancel!"
read
SCRIPT_DIR=/etc/openvpn/client-configs
KEY_GEN_DIR=/etc/openvpn/easy-rsa
KEY_DIR=/etc/openvpn/easy-rsa/keys
OUTPUT_DIR=/etc/openvpn/client-configs/${1}
LINUX_CONFIG=/etc/openvpn/client-configs/linux.conf
WIN_CONFIG=/etc/openvpn/client-configs/windows.conf

echo "client directory --> "${OUTPUT_DIR}
echo "Press enter to build cert and key!"
read
cd ${KEY_GEN_DIR}
source ./vars
./build-key ${1}

mkdir -p ${OUTPUT_DIR}/keys
cp ${KEY_DIR}/ca.crt ${OUTPUT_DIR}/keys/
cp ${KEY_DIR}/${1}.crt ${OUTPUT_DIR}/keys/
cp ${KEY_DIR}/${1}.key ${OUTPUT_DIR}/keys/
cp ${KEY_DIR}/ta.key ${OUTPUT_DIR}/keys/

cat ${BASE_CONFIG} <(echo -e '<ca>') \
    ${KEY_DIR}/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ${KEY_DIR}/${1}.crt \
    <(echo -e '</cert>\n<key>') \
    ${KEY_DIR}/${1}.key \
    <(echo -e '</key>\n<tls-auth>') \
    ${KEY_DIR}/ta.key \
    <(echo -e '</tls-auth>') \
    > ${OUTPUT_DIR}/${1}.ovpn


cp ${OUTPUT_DIR}/${1}.ovpn ${OUTPUT_DIR}/${1}.conf
echo "Using aes256 to encrypt conf file for secure transport to client"
SSLKEYCODE=$(hexdump -n 4 -e '2/4 "%04X" 1 "\n"' /dev/urandom)
echo "key is -->"${SSLKEYCODE}"will be stored with decryption command in "${OUTPUT_DIR}"/keys/enc.txt"
echo "key-begins-->" > ${OUTPUT_DIR}/keys/enc.txt
echo ${SSLKEYCODE} >> ${OUTPUT_DIR}/keys/enc.txt
echo "<--key-ends" >> ${OUTPUT_DIR}/keys/enc.txt
echo "Enc_command:" >> ${OUTPUT_DIR}/keys/enc.txt
echo "openssl enc -md sha256 -d -aes256 -in "${1}".conf.enc -out "${1}".conf -k "${SSLKEYCODE} >> ${OUTPUT_DIR}/keys/enc.txt
openssl enc -md sha256 -e -aes256 -in ${OUTPUT_DIR}/${1}.conf -out ${OUTPUT_DIR}/${1}.conf.enc -k ${SSLKEYCODE}
echo "Done. Config files *.conf and *.ovpn are the same!"
echo "Use ${1}.conf.enc for download/upload to client!"
echo "Use"
echo "-->openssl enc -md sha256 -d -aes256 -in /path/to/file/"${1}".conf.enc -out /path/to/file/"${1}".conf -k "${SSLKEYCODE}"<--"
echo "to decrypt the file to "${1}".conf"
echo "Older versions of that script used -md md5 to specify the key digest algorithm."
echo "When pressing enter konsole/terminal will be cleared(clear command)!"
echo "Happy networking!"
read
clear
echo "-->"
echo "listing directory:"
echo ${OUTPUT_DIR}
ls -lah ${OUTPUT_DIR}
echo
echo
echo "You are here:"${SCRIPT_DIR}
cd ${SCRIPT_DIR}
