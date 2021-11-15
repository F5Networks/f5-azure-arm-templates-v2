#  expectValue = "good"
#  scriptTimeout = 2
#  replayEnabled = false
#  replayTimeout = 20


TMP_DIR='/tmp/<DEWPOINT JOB ID>'
SSH_KEY=${TMP_DIR}/<RESOURCE GROUP>-private
PASSWORD='<SECRET VALUE>'

echo "--- Github Status ---"
github_response=`curl https://status.github.com/api/status.json?callback-apiStatus | jq .status --raw-output`

# build logs list
CUST_SCRIPT_LOC="/var/lib/waagent/custom-script/download/0"
LOGS="$CUST_SCRIPT_LOC/stdout $CUST_SCRIPT_LOC/stderr /var/log/waagent.log /var/log/cloud/startup-script.log"

if [[ "<PROVISION PUBLIC IP>" == "False" ]]; then
    echo 'MGMT PUBLIC IP IS NOT ENABLED'

    bastion_public_ip=$(echo $DEPLOYMENT | jq -r '.properties.outputs["bastionPublicIp"].value')
    echo "BASTION PUBLIC IP: $bastion_public_ip"
    bigip1_private_ip=$(echo $DEPLOYMENT | jq -r '.properties.outputs["bigIpInstance01ManagementPrivateIp"].value')
    echo "BIGIP1 PRIVATE IP: $bigip1_private_ip"
    bigip2_private_ip=$(echo $DEPLOYMENT | jq -r '.properties.outputs["bigIpInstance02ManagementPrivateIp"].value')
    echo "BIGIP2 PRIVATE IP: $bigip2_private_ip"

    for LOG in $LOGS; do
        echo "------------------------LOG:$LOG ------------------------"
        filename=$(basename ${LOG})
        echo $filename
        sshpass -p '${PASSWORD}' scp -o "StrictHostKeyChecking no" -o ProxyCommand="ssh -o 'StrictHostKeyChecking no' -i $SSH_KEY -W %h:%p azureuser@$bastion_public_ip" admin@${bigip1_private_ip}:${base}${LOG} ${TMP_DIR}/${filename}-<REGION>-bigip01
        sshpass -p '${PASSWORD}' scp -o "StrictHostKeyChecking no" -o ProxyCommand="ssh -o 'StrictHostKeyChecking no' -i $SSH_KEY -W %h:%p azureuser@$bastion_public_ip" admin@${bigip2_private_ip}:${base}${LOG} ${TMP_DIR}/${filename}-<REGION>-bigip02
        cat ${TMP_DIR}/${filename}-<REGION>-bigip01 2>/dev/null
        cat ${TMP_DIR}/${filename}-<REGION>-bigip02 2>/dev/null
        echo
    done
    ssh-keygen -R $bigip1_private_ip 2>/dev/null
    ssh-keygen -R $bigip2_private_ip 2>/dev/null
    ssh-keygen -R $bastion_public_ip 2>/dev/null
else
    echo 'MGMT PUBLIC IP IS ENABLED'

    bigip1_public_ip=$(echo $DEPLOYMENT | jq -r '.properties.outputs["bigIpInstance01ManagementPublicIp"].value')
    echo "BIGIP1 PUBLIC IP: $bigip1_public_ip"
    bigip2_public_ip=$(echo $DEPLOYMENT | jq -r '.properties.outputs["bigIpInstance02ManagementPublicIp"].value')
    echo "BIGIP2 PUBLIC IP: $bigip2_public_ip"

    for LOG in $LOGS; do
        echo "------------------------LOG:$LOG ------------------------"
        filename=$(basename ${LOG})
        echo $filename
        sshpass -p '${PASSWORD}' scp -o "StrictHostKeyChecking no" admin@${bigip1_public_ip}:${base}${LOG} ${TMP_DIR}/${filename}-<REGION>-bigip01
        sshpass -p '${PASSWORD}' scp -o "StrictHostKeyChecking no" admin@${bigip2_public_ip}:${base}${LOG} ${TMP_DIR}/${filename}-<REGION>-bigip02
        cat ${TMP_DIR}/${filename}-<REGION>-bigip01 2>/dev/null
        cat ${TMP_DIR}/${filename}-<REGION>-bigip02 2>/dev/null
        echo
    done
    ssh-keygen -R $bigip1_public_ip 2>/dev/null
    ssh-keygen -R $bigip2_public_ip 2>/dev/null
fi

if [[ $github_response == "good" ]]; then
    echo "GitHub status is good"
fi
