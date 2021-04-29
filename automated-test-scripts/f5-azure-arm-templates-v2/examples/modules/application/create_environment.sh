#  expectValue = "Deployment accepted"
#  expectFailValue = "Template validation failed"
#  scriptTimeout = 15
#  replayEnabled = false
#  replayTimeout = 0

TMP_DIR='/tmp/<DEWPOINT JOB ID>'
DEPLOY_BIGIQ='No'
DEPLOY_GTM='No'
DEPLOY_ROUTER='No'
BIG_IQ_LICENSE='DO_NOT_USE'
BIG_IQ_LICENSE_POOL='DO_NOT_USE'
GTM_LICENSE='DO_NOT_USE'
ROUTER_LICENSE='DO_NOT_USE'

# download and use --template-file because --template-uri is limiting
curl -k https://s3.amazonaws.com/f5-cft/QA/azure-environment.json -o ${TMP_DIR}/azure-environment.json

# get the public key from key vault
SSH_KEY=$(az keyvault secret show --vault-name dewdropKeyVault -n dewpt-public | jq .value --raw-output)

# get the private key from storage via key vault
STORAGE_KEY=$(az keyvault secret show --vault-name dewdropKeyVault -n dewdropkeystore1 | jq .value --raw-output)
az storage file download --share-name keyshare --path dewpt-private --dest ${TMP_DIR}/<RESOURCE GROUP>-private --account-name dewdropkeystore --account-key $STORAGE_KEY

chmod 600 ${TMP_DIR}/<RESOURCE GROUP>-private

# set vars
# stack-type
if [[ (<CREATE PUBLIC IP> == "Yes" || <CREATE PUBLIC IP> == "No") ]]; then
    CREATE_PUBLIC_IP='<CREATE PUBLIC IP>'
    if [[ ${CREATE_PUBLIC_IP} == "No" ]]; then
        STACK_TYPE='production-stack'
    else
        STACK_TYPE='existing-stack'
    fi
else
    # existing-stack or new-stack
    STACK_TYPE="<STACK TYPE>"
fi
echo "Stack type: $STACK_TYPE"

DEPLOY_PARAMS='{"stackType":{"value":"'"${STACK_TYPE}"'"},"bastionSshKey":{"value":"'"${SSH_KEY}"'"},"deployBigiq":{"value":"'"${DEPLOY_BIGIQ}"'"},"deployGtm":{"value":"'"${DEPLOY_GTM}"'"},"deployRouter":{"value":"'"${DEPLOY_ROUTER}"'"},"dnsLabel":{"value":"<RESOURCE GROUP>"},"bigiqPassword":{"value":"B!giq2017"},"gtmPassword":{"value":"B!gdns2017"},"routerPassword":{"value":"B!grtr2017"},"bigiqLicenseKey":{"value":"'"${BIG_IQ_LICENSE}"'"},"gtmLicenseKey":{"value":"'"${GTM_LICENSE}"'"},"routerLicenseKey":{"value":"'"${ROUTER_LICENSE}"'"},"licensePoolKeys":{"value":"'"${BIG_IQ_LICENSE_POOL}"'"}}'
DEPLOY_PARAMS_FILE=${TMP_DIR}/deploy_params.json

echo ${DEPLOY_PARAMS} > ${DEPLOY_PARAMS_FILE}
echo "DEBUG: DEPLOY PARAMS"
echo ${DEPLOY_PARAMS}

# validate the template
VALIDATION=$(az deployment group validate --resource-group <RESOURCE GROUP> --template-file ${TMP_DIR}/azure-environment.json --parameters @${DEPLOY_PARAMS_FILE} | jq .properties.provisioningState)
echo "Validation: $VALIDATION"

if [[ $VALIDATION == \"Succeeded\" ]]; then
    az deployment group create --verbose --no-wait --template-file ${TMP_DIR}/azure-environment.json -g <RESOURCE GROUP> -n <RESOURCE GROUP>-env --parameters @${DEPLOY_PARAMS_FILE}
    echo "Deployment accepted"
else
    echo "Template validation failed"
fi