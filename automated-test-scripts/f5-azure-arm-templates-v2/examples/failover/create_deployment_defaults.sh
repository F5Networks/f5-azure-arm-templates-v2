#  expectValue = "Template validation succeeded"
#  expectFailValue = "Template validation failed"
#  scriptTimeout = 15
#  replayEnabled = false
#  replayTimeout = 0

SRC_IP=$(curl ifconfig.me)/32
TMP_DIR='/tmp/<DEWPOINT JOB ID>'

# download and use --template-file because --template-uri is limiting
TEMPLATE_FILE=${TMP_DIR}/<RESOURCE GROUP>.json
curl -k <TEMPLATE URL> -o ${TEMPLATE_FILE}
echo "TEMPLATE URI: <TEMPLATE URL>"

SECRET_ID=$(az keyvault secret show --vault-name <RESOURCE GROUP>fv -n <RESOURCE GROUP>bigiq | jq .id --raw-output)
echo $SECRET_ID

SSH_KEY=$(az keyvault secret show --vault-name dewdropKeyVault -n dewpt-public | jq .value --raw-output)

NETWORK_PARAMS=''
if echo "<TEMPLATE URL>" | grep -q "existing-network"; then
    echo "Deploying existing network stack"
    MGMT_SUBNET_ID=$(az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-net-env | jq -r '.properties.outputs["subnets"].value[0]')
    EXT_SUBNET_ID=$(az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-net-env | jq -r '.properties.outputs["subnets"].value[1]')
    INT_SUBNET_ID=$(az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-net-env | jq -r '.properties.outputs["subnets"].value[2]')
    NETWORK_PARAMS=',"bigIpMgmtSubnetId":{"value":"'"${MGMT_SUBNET_ID}"'"},"bigIpExternalSubnetId":{"value":"'"${EXT_SUBNET_ID}"'"},"bigIpInternalSubnetId":{"value":"'"${INT_SUBNET_ID}"'"}'
    echo "Network params: $NETWORK_PARAMS"
else 
    NETWORK_PARAMS=',"restrictedSrcAddressVip":{"value":"'"${SRC_IP}"'"}'
fi

DEPLOY_PARAMS='{"uniqueString":{"value":"<RESOURCE GROUP>"},"sshKey":{"value":"'"${SSH_KEY}"'"},"restrictedSrcAddressApp":{"value":"'"${SRC_IP}"'"},"restrictedSrcAddressMgmt":{"value":"'"${SRC_IP}"'"},"bigIpPasswordSecretId":{"value":"'"${SECRET_ID}"'"},"cfeStorageAccountName":{"value":"<DEWPOINT JOB ID>stcfe"}'${NETWORK_PARAMS}'}'
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
