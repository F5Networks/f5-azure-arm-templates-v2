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

SUBNET_ID=$(az deployment group show -n <RESOURCE GROUP>-net-env -g <RESOURCE GROUP> | jq  -r .properties.outputs.subnets.value[0])
NSG_ID=$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq  -r .properties.outputs.nsgIds.value[0])
PUBLIC_IP_ID=""

if [[ "<CREATE AUTOSCALE>" == "False" ]]; then
    PUBLIC_IP_ID=$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq  -r .properties.outputs.mgmtIpIds.value[0])
fi

DEPLOY_PARAMS='{"adminUsername":{"value":"azureuser"},"sshKey":{"value":"'"${SSH_KEY}"'"},"createAutoscaleGroup":{"value":<CREATE AUTOSCALE>},"instanceName":{"value":"<VM NAME>"},"instanceType":{"value":"<INSTANCE TYPE>"},"nsgId":{"value":"'"${NSG_ID}"'"},"subnetId":{"value":"'"${SUBNET_ID}"'"},"publicIpId":{"value":"'"${PUBLIC_IP_ID}"'"},"cloudInitUrl":{"value":"<CLOUD INIT URL>"},"vmScaleSetMinCount":{"value":<VM SCALE SET MIN COUNT>},"vmScaleSetMaxCount":{"value":<VM SCALE SET MAX COUNT>}}'
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
