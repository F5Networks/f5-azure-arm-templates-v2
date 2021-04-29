#  expectValue = "SUCCEEDED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 5

# SSH login for <ADMIN USERNAME> is set when we provision the instances, the actual admin user password is configured by runtime init
TMP_DIR='/tmp/<DEWPOINT JOB ID>'
SSH_KEY=${TMP_DIR}/<RESOURCE GROUP>-private
PASSWORD=$(az vm show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-vm | jq -r .vmId)
SSH_PORT='22'
if [[ <NIC COUNT> -eq 1 ]]; then
    MGMT_PORT='8443'
else
    MGMT_PORT='443'
fi

if [[ <PROVISION PUBLIC IP> == False ]]; then
    # skipping this for now until we come up with new create_environment.sh for bastion host in mgmt vNet
    SSH_RESPONSE="encrypted-password !!"
    PASSWORD_RESPONSE="quickstart"
else
    HOST=$(az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP> | jq -r '.properties.outputs["bigIpManagementPublicIp"].value')
    echo "Host: $HOST"
    ssh-keygen -R ${HOST} 2>/dev/null
    SSH_RESPONSE=$(ssh -o "StrictHostKeyChecking no" -i $SSH_KEY azureuser@${HOST} -p $SSH_PORT 'list auth user azureuser')
    PASSWORD_RESPONSE=$(curl -sku quickstart:${PASSWORD} https://${HOST}:${MGMT_PORT}/mgmt/tm/auth/user/quickstart | jq -r .description)
fi
echo "SSH_RESPONSE: ${SSH_RESPONSE}"
echo "PASSWORD_RESPONSE: ${PASSWORD_RESPONSE}"

if echo ${SSH_RESPONSE} | grep -q "encrypted-password !!" && echo ${PASSWORD_RESPONSE} | grep -q "quickstart"; then
    echo "SUCCEEDED"
else
    echo "FAILED"
fi