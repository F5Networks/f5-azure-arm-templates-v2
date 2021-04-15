#  expectValue = "SUCCEEDED"
#  expectFailValue = "FAILED"
#  scriptTimeout = 15
#  replayEnabled = false
#  replayTimeout = 0

TMP_DIR='/tmp/<DEWPOINT JOB ID>'
# get the public key from key vault
SSH_KEY=$(az keyvault secret show --vault-name dewdropKeyVault -n dewpt-public | jq .value --raw-output)

# get the private key from storage via key vault
STORAGE_KEY=$(az keyvault secret show --vault-name dewdropKeyVault -n dewdropkeystore1 | jq .value --raw-output)
az storage file download --share-name keyshare --path dewpt-private --dest ${TMP_DIR}/<RESOURCE GROUP>-private --account-name dewdropkeystore --account-key $STORAGE_KEY

chmod 600 ${TMP_DIR}/<RESOURCE GROUP>-private

### since we are creating the full stack, if we want to test production stack we will need to create the bastion host after the template deployment
### (saving for later)
# response="VM running"
# if [[ <PROVISION PUBLIC IP> == False ]]; then
#     response=$(az vm create -n <RESOURCE GROUP>-bastionvm -g <RESOURCE GROUP> --image UbuntuLTS --vnet-name <RESOURCE GROUP>-vnet --subnet subnet0 --private-ip-address 10.0.0.50 --public-ip-sku Standard --admin-username azureuser --admin-password 'B!giq2017P@zz' | jq -r .powerState)
# fi

# if [[ $response == "VM running" ]]; then
#     echo "Deployment accepted"
# else
#     echo "Template validation failed"
# fi

if [ $? -eq 0 ]; then
    echo "SUCCEEDED"
else
    echo "FAILED"
fi