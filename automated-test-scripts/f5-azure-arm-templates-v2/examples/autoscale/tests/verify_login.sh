#  expectValue = "Succeeded"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10

# SSH login for <ADMIN USERNAME> is set when we provision the instances, the actual admin user password is configured by runtime init
TMP_DIR='/tmp/<DEWPOINT JOB ID>'
SSH_KEY=${TMP_DIR}/<RESOURCE GROUP>-private
PASSWORD='<SECRET VALUE>'
MGMT_PORT='8443'
SSH_PORT='22'

IP1=$(az vmss list-instance-public-ips -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bigip-vmss | jq -r .[0].ipAddress)
echo "IP1: ${IP1}"

ssh-keygen -R ${IP1} 2>/dev/null
SSH_RESPONSE=$(ssh -o "StrictHostKeyChecking no" -i $SSH_KEY azureuser@${IP1} -p $SSH_PORT 'list auth user azureuser')
echo "SSH_RESPONSE: ${SSH_RESPONSE}"

PASSWORD_RESPONSE=$(curl -skvvu admin:${PASSWORD} https://${IP1}:${MGMT_PORT}/mgmt/tm/auth/user/admin | jq -r .description)
echo "PASSWORD_RESPONSE: ${PASSWORD_RESPONSE}"

if echo ${SSH_RESPONSE} | grep -q "encrypted-password !!" && echo ${PASSWORD_RESPONSE} | grep -q "Admin User"; then
    IP1_LOGIN='Succeeded'
else
    IP1_LOGIN='Failed'
fi

IP2=$(az vmss list-instance-public-ips -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bigip-vmss | jq -r .[1].ipAddress)
echo "IP2: ${IP2}"

ssh-keygen -R ${IP2} 2>/dev/null
SSH_RESPONSE=$(ssh -o "StrictHostKeyChecking no" -i $SSH_KEY azureuser@${IP2} -p $SSH_PORT 'list auth user azureuser')
echo "SSH_RESPONSE: ${SSH_RESPONSE}"

PASSWORD_RESPONSE=$(curl -skvvu admin:${PASSWORD} https://${IP2}:${MGMT_PORT}/mgmt/tm/auth/user/admin | jq -r .description)
echo "PASSWORD_RESPONSE: ${PASSWORD_RESPONSE}"

if echo ${SSH_RESPONSE} | grep -q "encrypted-password !!" && echo ${PASSWORD_RESPONSE} | grep -q "Admin User"; then
    IP2_LOGIN='Succeeded'
else
    IP2_LOGIN='Failed'
fi

if [[ ${IP1_LOGIN} == "Succeeded" && ${IP2_LOGIN} == "Succeeded" ]]; then
    echo 'Succeeded'
else
    echo 'Failed'
fi