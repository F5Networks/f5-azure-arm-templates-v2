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

VNET_ID=$(az network vnet show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-vnet | jq -r .id)
VMSS_ID=$(az vmss show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-vmss | jq -r .id)

DEPLOY_PARAMS='{"vmssId":{"value":"'"${VMSS_ID}"'"},"bigIqAddress":{"value":"<BIGIQ ADDRESS>"},"bigIqPassword":{"value":"<PASSWORD>"},"bigIqLicensePool":{"value":"clpv2"},"bigIqUsername":{"value":"<USERNAME>"},"bigIqTenant":{"value":"<TENANT>"},"bigIqUtilitySku":{"value":"F5-BIG-MSP-BT-1G"},"functionAppName":{"value":"<FUNCTION APP NAME>"},"functionAppSku":{"value":<FUNCTION APP SKU>},"functionAppVnetId":{"value":"'"${VNET_ID}"'"},"tagValues":{"value":{"application":"APP","cost":"COST","environment":"ENV","group":"GROUP","owner":"OWNER"}}}'

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
