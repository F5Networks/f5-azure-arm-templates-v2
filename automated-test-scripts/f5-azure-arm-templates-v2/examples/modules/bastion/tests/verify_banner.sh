#  expectValue = "Succeeded"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10

TMP_DIR='/tmp/<DEWPOINT JOB ID>'
STORAGE_KEY=$(az keyvault secret show --vault-name dewdropKeyVault -n dewdropkeystore1 | jq .value --raw-output)
az storage file download --share-name keyshare --path dewpt-private --dest ${TMP_DIR}/<RESOURCE GROUP>-private --account-name dewdropkeystore --account-key $STORAGE_KEY
chmod 600 ${TMP_DIR}/<RESOURCE GROUP>-private

SSH_KEY=${TMP_DIR}/<RESOURCE GROUP>-private
SSH_PORT='22'

case <CREATE AUTOSCALE> in
"True")
    BASTION_HOST=$(az vmss list-instance-public-ips -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bastion-vmss | jq -r .[0].ipAddress) ;;
"False")
    BASTION_HOST=$(az vm list-ip-addresses -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bastion-vm | jq -r .[0].virtualMachine.network.publicIpAddresses[0].ipAddress) ;;
*)
    echo "Did not find boolean for provisioning autoscale" ;;
esac

echo "Bastion host: $BASTION_HOST"
SSH_RESPONSE=$(ssh -o "StrictHostKeyChecking no" -i $SSH_KEY azureuser@${BASTION_HOST} -p $SSH_PORT 'cat /etc/motd')

if echo ${SSH_RESPONSE} | grep -q "***** Welcome to Bastion Host *****"; then
    echo 'Succeeded'
else
    echo 'Failed'
fi
