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

case <PROVISION PUBLIC IP> in
"False")
    BASTION_HOST=`az vmss list-instance-public-ips -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bastion-vmss | jq -r .[0].ipAddress`
    echo "Verify bastion host: $BASTION_HOST"

    ssh-keygen -R ${BASTION_HOST} 2>/dev/null
    IP1=$(az vmss nic list -g <RESOURCE GROUP> --vmss-name <RESOURCE GROUP>-bigip-vmss | jq -r .[0].ipConfigurations[0].privateIpAddress)
    echo "IP1: ${IP1}"

    SSH_RESPONSE_1=$(ssh -o "StrictHostKeyChecking no" -i $SSH_KEY -o ProxyCommand="ssh -o 'StrictHostKeyChecking no' -i $SSH_KEY -W %h:%p azureuser@${BASTION_HOST}" azureuser@"${IP1}" 'list auth user azureuser')
    echo "SSH_RESPONSE_1: ${SSH_RESPONSE_1}"

    PASSWORD_RESPONSE_1=$(ssh -o "StrictHostKeyChecking no" -i $SSH_KEY azureuser@${BASTION_HOST} "curl -skvvu admin:${PASSWORD} --connect-timeout 10 https://${IP1}:${MGMT_PORT}/mgmt/tm/auth/user/admin" | jq -r .description)
    echo "PASSWORD_RESPONSE_1: ${PASSWORD_RESPONSE_1}"

    IP2=$(az vmss nic list -g <RESOURCE GROUP> --vmss-name <RESOURCE GROUP>-bigip-vmss | jq -r .[1].ipConfigurations[0].privateIpAddress)
    echo "IP2: ${IP2}"

    SSH_RESPONSE_2=$(ssh -o "StrictHostKeyChecking no" -i $SSH_KEY -o ProxyCommand="ssh -o 'StrictHostKeyChecking no' -i $SSH_KEY -W %h:%p azureuser@${BASTION_HOST}" azureuser@"${IP2}" 'list auth user azureuser')
    echo "SSH_RESPONSE_2: ${SSH_RESPONSE_2}"

    PASSWORD_RESPONSE_2=$(ssh -o "StrictHostKeyChecking no" -i $SSH_KEY azureuser@${BASTION_HOST} "curl -skvvu admin:${PASSWORD} --connect-timeout 10 https://${IP2}:${MGMT_PORT}/mgmt/tm/auth/user/admin" | jq -r .description)
    echo "PASSWORD_RESPONSE_2: ${PASSWORD_RESPONSE_2}" ;;
"True")
    IP1=$(az vmss list-instance-public-ips -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bigip-vmss | jq -r .[0].ipAddress)
    echo "IP1: ${IP1}"

    ssh-keygen -R ${IP1} 2>/dev/null
    SSH_RESPONSE_1=$(ssh -o "StrictHostKeyChecking no" -i $SSH_KEY azureuser@${IP1} -p $SSH_PORT 'list auth user azureuser')
    echo "SSH_RESPONSE_1: ${SSH_RESPONSE_1}"

    PASSWORD_RESPONSE_1=$(curl -skvvu admin:${PASSWORD} https://${IP1}:${MGMT_PORT}/mgmt/tm/auth/user/admin | jq -r .description)
    echo "PASSWORD_RESPONSE_1: ${PASSWORD_RESPONSE_1}"

    IP2=$(az vmss list-instance-public-ips -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bigip-vmss | jq -r .[1].ipAddress)
    echo "IP2: ${IP2}"

    ssh-keygen -R ${IP2} 2>/dev/null
    SSH_RESPONSE_2=$(ssh -o "StrictHostKeyChecking no" -i $SSH_KEY azureuser@${IP2} -p $SSH_PORT 'list auth user azureuser')
    echo "SSH_RESPONSE_2: ${SSH_RESPONSE_2}"

    PASSWORD_RESPONSE_2=$(curl -skvvu admin:${PASSWORD} https://${IP2}:${MGMT_PORT}/mgmt/tm/auth/user/admin | jq -r .description)
    echo "PASSWORD_RESPONSE_2: ${PASSWORD_RESPONSE_2}" ;;
*)
    echo "Did not find boolean for provisioning public IP" ;;
esac

if echo ${SSH_RESPONSE_1} | grep -q "encrypted-password !!" && echo ${PASSWORD_RESPONSE_1} | grep -q "Admin User"; then
    IP1_LOGIN='Succeeded'
else
    IP1_LOGIN='Failed'
fi

if echo ${SSH_RESPONSE_2} | grep -q "encrypted-password !!" && echo ${PASSWORD_RESPONSE_2} | grep -q "Admin User"; then
    IP2_LOGIN='Succeeded'
else
    IP2_LOGIN='Failed'
fi

if [[ ${IP1_LOGIN} == "Succeeded" && ${IP2_LOGIN} == "Succeeded" ]]; then
    echo 'Succeeded'
else
    echo 'Failed'
fi