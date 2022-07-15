#  expectValue = "SUCCESS"
#  scriptTimeout = 2
#  replayEnabled = true
#  replayTimeout = 20


FLAG='FAIL'
TMP_DIR='/tmp/<DEWPOINT JOB ID>'
SSH_KEY=${TMP_DIR}/<RESOURCE GROUP>-private
PASSWORD='<SECRET VALUE>'
DEPLOYMENT=$(az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP> | jq -r .)

if [[ "<PROVISION PUBLIC IP>" == "False" ]]; then
    echo 'MGMT PUBLIC IP IS NOT ENABLED'

    bastion_public_ip=$(az vm list-ip-addresses -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bastion-vm-01 | jq -r .[0].virtualMachine.network.publicIpAddresses[0].ipAddress)
    echo "BASTION PUBLIC IP: $bastion_public_ip"
    bigip1_private_ip=$(echo $DEPLOYMENT | jq -r '.properties.outputs["bigIpInstance01ManagementPrivateIp"].value')
    echo "BIGIP1 PRIVATE IP: $bigip1_private_ip"
    bigip2_private_ip=$(echo $DEPLOYMENT | jq -r '.properties.outputs["bigIpInstance02ManagementPrivateIp"].value')
    echo "BIGIP2 PRIVATE IP: $bigip2_private_ip"

    state=$(sshpass -p ${PASSWORD} ssh -o "StrictHostKeyChecking no" -o ProxyCommand="ssh -o 'StrictHostKeyChecking no' -i $SSH_KEY -W %h:%p azureuser@$bastion_public_ip" admin@${bigip1_private_ip} "tmsh show sys failover")
    echo "State: $state"
    active=$(echo $state |grep active)

    case $active in
    active)
      echo "Current State: $active, nothing to do, grab bigip2 status"
      result=$(sshpass -p ${PASSWORD} ssh -o "StrictHostKeyChecking no" -o ProxyCommand="ssh -o 'StrictHostKeyChecking no' -i $SSH_KEY -W %h:%p azureuser@$bastion_public_ip" admin@${bigip2_private_ip} "tmsh show sys failover")  ;;
    *)
      echo "Current State: $active, setting system to standby on BIGIP2"
      sshpass -p ${PASSWORD} ssh -o "StrictHostKeyChecking no" -o ProxyCommand="ssh -o 'StrictHostKeyChecking no' -i $SSH_KEY -W %h:%p azureuser@$bastion_public_ip" admin@${bigip2_private_ip} "tmsh run sys failover standby"
      result=$(sshpass -p ${PASSWORD} ssh -o "StrictHostKeyChecking no" -o ProxyCommand="ssh -o 'StrictHostKeyChecking no' -i $SSH_KEY -W %h:%p azureuser@$bastion_public_ip" admin@${bigip2_private_ip} "tmsh show sys failover")  ;;
    esac
else
    echo 'MGMT PUBLIC IP IS ENABLED'

    bigip1_public_ip=$(echo $DEPLOYMENT | jq -r '.properties.outputs["bigIpInstance01ManagementPublicIp"].value')
    echo "BIGIP1 PUBLIC IP: $bigip1_public_ip"
    bigip2_public_ip=$(echo $DEPLOYMENT | jq -r '.properties.outputs["bigIpInstance02ManagementPublicIp"].value')
    echo "BIGIP2 PUBLIC IP: $bigip2_public_ip"

    state=$(sshpass -p ${PASSWORD} ssh -o "StrictHostKeyChecking no" admin@${bigip1_public_ip} "tmsh show sys failover")
    echo "State: $state"
    active=$(echo $state |grep active)

    case $active in
    active)
      echo "Current State: $active, nothing to do, grab bigip2 status"
      result=$(sshpass -p ${PASSWORD} ssh -o "StrictHostKeyChecking no" admin@${bigip2_public_ip} "tmsh show sys failover")  ;;
    *)
      echo "Current State: $active, setting system to standby on BIGIP2"
      sshpass -p ${PASSWORD} ssh -o "StrictHostKeyChecking no" admin@${bigip2_public_ip} "tmsh run sys failover standby"
      result=$(sshpass -p ${PASSWORD} ssh -o "StrictHostKeyChecking no" admin@${bigip2_public_ip} "tmsh show sys failover")  ;;
    esac
fi

# evaluate result
if echo $result | grep 'Failover standby'; then
    echo "SUCCESS"
else
    echo "FAILED"
fi
