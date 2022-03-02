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

if [ $? -eq 0 ]; then
    echo "SUCCEEDED"
else
    echo "FAILED"
fi