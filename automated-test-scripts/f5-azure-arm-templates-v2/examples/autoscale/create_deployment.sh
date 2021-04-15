#  expectValue = "Template validation succeeded"
#  expectFailValue = "Template validation failed"
#  scriptTimeout = 15
#  replayEnabled = false
#  replayTimeout = 0

TMP_DIR='/tmp/<DEWPOINT JOB ID>'

# download and use --template-file because --template-uri is limiting
TEMPLATE_FILE=${TMP_DIR}/<RESOURCE GROUP>.json
curl -k <TEMPLATE URL> -o ${TEMPLATE_FILE}
echo "TEMPLATE URI: <TEMPLATE URL>"

SSH_KEY=$(az keyvault secret show --vault-name dewdropKeyVault -n dewpt-public | jq .value --raw-output)
STORAGE_ACCOUNT_NAME=$(echo st<RESOURCE GROUP>tmpl | tr -d -)
STORAGE_ACCOUNT_FQDN=$(az storage account show -n ${STORAGE_ACCOUNT_NAME} -g <RESOURCE GROUP> | jq -r .primaryEndpoints.blob)

if [[ <LICENSE TYPE> == "bigiq" ]]; then
    BIGIQ_ADDRESS=`az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-env | jq '.properties.outputs["bigiqIp"].value' --raw-output | cut -d' ' -f1`
    BIGIQ_VNET_ID=$(az network vnet show -g <RESOURCE GROUP> -n existingStackVnet | jq -r .id)
    BIGIQ_PARAMS=',"bigIqAddress":{"value":"'"${BIGIQ_ADDRESS}"'"},"bigIqUsername":{"value":"azureuser"},"bigIqPassword":{"value":"B!giq2017"},"bigIqLicensePool":{"value":"clpv2"},"bigIqTenant":{"value":"<BIGIQ TENANT>"},"bigIqUtilitySku":{"value":"F5-BIG-MSP-BT-1G"},"bigIqVnetId":{"value":"'"${BIGIQ_VNET_ID}"'"}'
else
    BIGIQ_PARAMS=''
fi


WORKSPACE_ID=$(az monitor log-analytics workspace show --resource-group <RESOURCE GROUP> --workspace-name <RESOURCE GROUP>-log-wrkspc --query customerId | tr -d '"')

DEPLOY_PARAMS='{"templateBaseUrl":{"value":"'"${STORAGE_ACCOUNT_FQDN}"'"},"artifactLocation":{"value":"<ARTIFACT LOCATION>"},"uniqueString":{"value":"<RESOURCE GROUP>"},"workspaceId":{"value":"'"${WORKSPACE_ID}"'"},"sshKey":{"value":"'"${SSH_KEY}"'"},"appContainerName":{"value":"<APP CONTAINER>"},"restrictedSrcAddressMgmt":{"value":"<RESTRICTED SRC ADDRESS>"},"image":{"value":"<IMAGE>"},"bigIpRuntimeInitConfig":{"value":"<RUNTIME CONFIG>"},"bigIpScalingMaxSize":{"value":<SCALING MAX>},"bigIpScalingMinSize":{"value":<SCALING MIN>},"newPassword":{"value":"<SECRET VALUE>"},"useAvailabilityZones":{"value":<USE AVAILABILITY ZONES>}'${BIGIQ_PARAMS}'}'
DEPLOY_PARAMS_FILE=${TMP_DIR}/deploy_params.json

# save deployment parameters to a file, to avoid weird parameter parsing errors with certain values
# when passing as a variable. I.E. when providing an sshPublicKey
echo ${DEPLOY_PARAMS} > ${DEPLOY_PARAMS_FILE}

echo "DEBUG: DEPLOY PARAMS"
echo ${DEPLOY_PARAMS}

VALIDATE_RESPONSE=$(az deployment group validate --resource-group <RESOURCE GROUP> --template-file ${TEMPLATE_FILE} --parameters @${DEPLOY_PARAMS_FILE})
VALIDATION=$(echo ${VALIDATE_RESPONSE} | jq .properties.provisioningState)
if [[ $VALIDATION == \"Succeeded\" ]]; then
    az deployment group create --verbose --no-wait --template-file ${TEMPLATE_FILE} -g <RESOURCE GROUP> -n <RESOURCE GROUP> --parameters @${DEPLOY_PARAMS_FILE}
    echo "Template validation succeeded"
else
    echo "Template validation failed: ${VALIDATE_RESPONSE}"
fi
