#  expectValue = "SUCCESS"
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

    SSH_RESPONSE=$(ssh -o "StrictHostKeyChecking no" -i $SSH_KEY -o ProxyCommand="ssh -o 'StrictHostKeyChecking no' -i $SSH_KEY -W %h:%p azureuser@${BASTION_HOST}" azureuser@"${IP1}" "bash -c 'cat /config/cloud/telemetry_install_params.tmp'")
    echo "SSH_RESPONSE: ${SSH_RESPONSE}" ;;
"True")
    IP1=$(az vmss list-instance-public-ips -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bigip-vmss | jq -r .[0].ipAddress)
    echo "IP1: ${IP1}"

    ssh-keygen -R ${IP1} 2>/dev/null
    SSH_RESPONSE=$(ssh -o "StrictHostKeyChecking no" -i $SSH_KEY azureuser@${IP1} -p $SSH_PORT "bash -c 'cat /config/cloud/telemetry_install_params.tmp'")
    echo "SSH_RESPONSE: ${SSH_RESPONSE}" ;;
*)
    echo "Did not find boolean for provisioning public IP" ;;
esac

if echo $response  | grep "examples/modules/bigip-autoscale/bigip.json"; then
    echo "SUCCESS"
fi
