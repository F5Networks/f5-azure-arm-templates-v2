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

MGMT_SUBNET_ID=$(az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-net-env | jq -r '.properties.outputs["subnets"].value[0]')
echo "MGMT_SUBNET_ID is "
echo $MGMT_SUBNET_ID

EXT_SUBNET_ID=''
if [[ <NIC COUNT> -ge 2 ]]; then
    EXT_SUBNET_ID=$(az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-net-env | jq -r '.properties.outputs["subnets"].value[1]')
    echo "EXT_SUBNET_ID is "
    echo $EXT_SUBNET_ID
fi

INT_SUBNET_ID=''
if [[ <NIC COUNT> -ge 3 ]]; then
    INT_SUBNET_ID=$(az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-net-env | jq -r '.properties.outputs["subnets"].value[2]')
    echo "INT_SUBNET_ID is "
    echo $INT_SUBNET_ID
fi 

## Create runtime configs with yq
if [[ "<PROVISION APP>" == "False" ]]; then
    cp /$PWD/examples/quickstart/bigip-configurations/runtime-init-conf-<NIC COUNT>nic-<LICENSE TYPE>.yaml <DEWPOINT JOB ID>.yaml
else
    cp /$PWD/examples/quickstart/bigip-configurations/runtime-init-conf-<NIC COUNT>nic-<LICENSE TYPE>-with-app.yaml <DEWPOINT JOB ID>.yaml
fi

# Disable AutoPhoneHome
/usr/bin/yq e ".extension_services.service_operations.[0].value.Common.My_System.autoPhonehome = false" -i <DEWPOINT JOB ID>.yaml

# Add BYOL license to declaration
if [[ <LICENSE TYPE> == "byol" ]]; then
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.My_License.regKey = \"<AUTOFILL EVAL LICENSE KEY>\"" -i <DEWPOINT JOB ID>.yaml
fi

if [[ "<PROVISION APP>" == "True" ]]; then
    # Use CDN for WAF policy since failover not published yet
    /usr/bin/yq e ".extension_services.service_operations.[1].value.Tenant_1.Shared.Custom_WAF_Policy.url = \"https://cdn.f5.com/product/cloudsolutions/solution-scripts/Rapid_Deployment_Policy_13_1.xml\"" -i <DEWPOINT JOB ID>.yaml
fi

# print out config file
/usr/bin/yq e <DEWPOINT JOB ID>.yaml

CONFIG_RESULT=$(az storage blob upload -f <DEWPOINT JOB ID>.yaml --account-name ${STORAGE_ACCOUNT_NAME} -c templates -n <DEWPOINT JOB ID>.yaml)
RUNTIME_CONFIG_URL=${STORAGE_ACCOUNT_FQDN}templates/<DEWPOINT JOB ID>.yaml

if [[ <USE DEFAULT PARAMETERS> == 'Yes' ]]; then
    DEPLOY_PARAMS='{"uniqueString":{"value":"<RESOURCE GROUP>"},"sshKey":{"value":"'"${SSH_KEY}"'"},"restrictedSrcAddressApp":{"value":"<RESTRICTED SRC ADDRESS APP>"},"restrictedSrcAddressMgmt":{"value":"<RESTRICTED SRC ADDRESS>"}}'
else
    DEPLOY_PARAMS='{"templateBaseUrl":{"value":"'"${STORAGE_ACCOUNT_FQDN}"'"},"artifactLocation":{"value":"<ARTIFACT LOCATION>"},"uniqueString":{"value":"<RESOURCE GROUP>"},"provisionPublicIpMgmt":{"value":<PROVISION PUBLIC IP>},"provisionServicePublicIp":{"value":<PROVISION APP>},"sshKey":{"value":"'"${SSH_KEY}"'"},"bigIpInstanceType":{"value":"<INSTANCE TYPE>"},"bigIpImage":{"value":"<IMAGE>"},"bigIpMgmtSubnetId":{"value":"'"${MGMT_SUBNET_ID}"'"},"bigIpExternalSubnetId":{"value":"'"${EXT_SUBNET_ID}"'"},"bigIpInternalSubnetId":{"value":"'"${INT_SUBNET_ID}"'"},"bigIpMgmtSelfAddress":{"value":"<SELF MGMT>"},"bigIpExternalSelfAddress":{"value":"<SELF EXT>"},"bigIpInternalSelfAddress":{"value":"<SELF INT>"},"servicePrivateIpAddress":{"value":"<EXT VIP ADDRESS>"},"restrictedSrcAddressApp":{"value":"<RESTRICTED SRC ADDRESS APP>"},"restrictedSrcAddressMgmt":{"value":"<RESTRICTED SRC ADDRESS>"},"bigIpRuntimeInitConfig":{"value":"'"${RUNTIME_CONFIG_URL}"'"},"useAvailabilityZones":{"value":<USE AVAILABILITY ZONES>},"numNics":{"value":<NIC COUNT>}}'
fi

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
