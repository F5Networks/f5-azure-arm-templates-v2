#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 5


FLAG='FAIL'
TMP_DIR='/tmp/<DEWPOINT JOB ID>'
SSH_KEY=${TMP_DIR}/<RESOURCE GROUP>-private
PASSWORD='<SECRET VALUE>'
DEPLOYMENT=$(az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP> | jq -r .)

if [[ "<PROVISION PUBLIC IP>" == "False" ]]; then
    echo 'MGMT PUBLIC IP IS NOT ENABLED'

    bastion_public_ip=$(az vm list-ip-addresses -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bastion-vm | jq -r .[0].virtualMachine.network.publicIpAddresses[0].ipAddress)
    echo "BASTION PUBLIC IP: $bastion_public_ip"
    bigip1_private_ip=$(echo $DEPLOYMENT | jq -r '.properties.outputs["bigIpInstance01ManagementPrivateIp"].value')
    echo "BIGIP1 PRIVATE IP: $bigip1_private_ip"
    bigip2_private_ip=$(echo $DEPLOYMENT | jq -r '.properties.outputs["bigIpInstance02ManagementPrivateIp"].value')
    echo "BIGIP2 PRIVATE IP: $bigip2_private_ip"

    BIGIP1_SSH_RESPONSE=$(sshpass -p ${PASSWORD} ssh -o "StrictHostKeyChecking no" -o ProxyCommand="ssh -o 'StrictHostKeyChecking no' -i $SSH_KEY -W %h:%p azureuser@$bastion_public_ip" admin@${bigip1_private_ip} "tmsh list auth user admin")
    echo "BIGIP1_RESPONSE: ${BIGIP1_SSH_RESPONSE}"
    BIGIP2_SSH_RESPONSE=$(sshpass -p ${PASSWORD} ssh -o "StrictHostKeyChecking no" -o ProxyCommand="ssh -o 'StrictHostKeyChecking no' -i $SSH_KEY -W %h:%p azureuser@$bastion_public_ip" admin@${bigip2_private_ip} "tmsh list auth user admin")
    echo "BIGIP2_RESPONSE: ${BIGIP2_SSH_RESPONSE}"

    BIGIP1_RESPONSE=$(ssh -i $SSH_KEY azureuser@$bastion_public_ip "curl -sku admin:${PASSWORD} https://${bigip1_private_ip}:443/mgmt/tm/auth/user/admin" | jq -r .description)
    echo "BIGIP1_RESPONSE: ${BIGIP1_RESPONSE}"

    BIGIP2_RESPONSE=$(ssh -i $SSH_KEY azureuser@$bastion_public_ip "curl -sku admin:${PASSWORD} https://${bigip2_private_ip}:443/mgmt/tm/auth/user/admin" | jq -r .description)
    echo "BIGIP2_RESPONSE: ${BIGIP2_RESPONSE}"

else
    echo 'MGMT PUBLIC IP IS ENABLED'

    bigip1_public_ip=$(echo $DEPLOYMENT | jq -r '.properties.outputs["bigIpInstance01ManagementPublicIp"].value')
    echo "BIGIP1 PUBLIC IP: $bigip1_public_ip"
    bigip2_public_ip=$(echo $DEPLOYMENT | jq -r '.properties.outputs["bigIpInstance02ManagementPublicIp"].value')
    echo "BIGIP2 PUBLIC IP: $bigip2_public_ip"

    BIGIP1_SSH_RESPONSE=$(sshpass -p ${PASSWORD} ssh -o "StrictHostKeyChecking no" admin@${bigip1_public_ip} "tmsh list auth user admin")
    echo "BIGIP1_RESPONSE: ${BIGIP1_SSH_RESPONSE}"
    BIGIP2_SSH_RESPONSE=$(sshpass -p ${PASSWORD} ssh -o "StrictHostKeyChecking no" admin@${bigip2_public_ip} "tmsh list auth user admin")
    echo "BIGIP2_RESPONSE: ${BIGIP2_SSH_RESPONSE}"

    BIGIP1_RESPONSE=$(curl -sku admin:${PASSWORD} https://${bigip1_public_ip}:443/mgmt/tm/auth/user/admin | jq -r .description)
    echo "BIGIP1_RESPONSE: ${BIGIP1_RESPONSE}"

    BIGIP2_RESPONSE=$(curl -sku admin:${PASSWORD} https://${bigip2_public_ip}:443/mgmt/tm/auth/user/admin | jq -r .description)
    echo "BIGIP2_RESPONSE: ${BIGIP2_RESPONSE}"
fi

# evaluate responses
if echo ${BIGIP1_SSH_RESPONSE} | grep -q "encrypted-password" && echo ${BIGIP2_SSH_RESPONSE} | grep -q "encrypted-password" && echo ${BIGIP1_RESPONSE} | grep -q "Admin User" && echo ${BIGIP2_RESPONSE} | grep -q "Admin User"; then
    FLAG='SUCCESS'
fi

echo $FLAG
