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

SSH_KEY=$(az keyvault secret show --vault-name dewdropKeyVault -n dewpt-public | jq .value --raw-output)
STORAGE_ACCOUNT_NAME=$(echo st<RESOURCE GROUP>tmpl | tr -d -)
STORAGE_ACCOUNT_FQDN=$(az storage account show -n ${STORAGE_ACCOUNT_NAME} -g <RESOURCE GROUP> | jq -r .primaryEndpoints.blob)

SECRET_ID=''
SECRET_VALUE=''
if [[ "<CREATE SECRET>" == "True" ]]; then
    SECRET_VALUE='<SECRET VALUE>'
    echo "SECRET_VALUE: $SECRET_VALUE"    
else
    SECRET_ID=$(az keyvault secret show --vault-name <RESOURCE GROUP>fv -n <RESOURCE GROUP>bigiq | jq .id --raw-output)
    echo "SECRET_ID: $SECRET_ID"    
fi

IDENTITY=''
if [[ "<CREATE IDENTITY>" == "False" ]]; then
    IDENTITY=$(az identity show -g <RESOURCE GROUP> -n <RESOURCE GROUP>id | jq -r .id)
    echo "IDENTITY: $IDENTITY"
fi

MGMT_SUBNET_ID=$(az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-net-env | jq -r '.properties.outputs["subnets"].value[0]')
echo "MGMT_SUBNET_ID is "
echo $MGMT_SUBNET_ID

EXT_SUBNET_ID=$(az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-net-env | jq -r '.properties.outputs["subnets"].value[1]')
echo "EXT_SUBNET_ID is "
echo $EXT_SUBNET_ID

INT_SUBNET_ID=''
if [[ <NIC COUNT> == 3 ]]; then
    INT_SUBNET_ID=$(az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-net-env | jq -r '.properties.outputs["subnets"].value[2]')
fi
echo "INT_SUBNET_ID is "
echo $INT_SUBNET_ID

# Add BYOL license to parameters
LIC_KEY_1=""
LIC_KEY_2=""
if [[ <LICENSE TYPE> == "byol" ]]; then
    LIC_KEY_1="<AUTOFILL EVAL LICENSE KEY>"
    LIC_KEY_2="<AUTOFILL EVAL LICENSE KEY 2>"
fi

## Create runtime configs with yq
if [[ "<PROVISION APP>" == "False" ]]; then
    cp /$PWD/examples/failover/bigip-configurations/runtime-init-conf-<NIC COUNT>nic-<LICENSE TYPE>-instance01.yaml <DEWPOINT JOB ID>01.yaml
    cp /$PWD/examples/failover/bigip-configurations/runtime-init-conf-<NIC COUNT>nic-<LICENSE TYPE>-instance02.yaml <DEWPOINT JOB ID>02.yaml
    do_index=2
else
    cp /$PWD/examples/failover/bigip-configurations/runtime-init-conf-<NIC COUNT>nic-<LICENSE TYPE>-instance01-with-app.yaml <DEWPOINT JOB ID>01.yaml
    cp /$PWD/examples/failover/bigip-configurations/runtime-init-conf-<NIC COUNT>nic-<LICENSE TYPE>-instance02-with-app.yaml <DEWPOINT JOB ID>02.yaml
    do_index=3
fi

# Set log level
/usr/bin/yq e ".controls.logLevel = \"<LOG LEVEL>\"" -i <DEWPOINT JOB ID>01.yaml
/usr/bin/yq e ".controls.logLevel = \"<LOG LEVEL>\"" -i <DEWPOINT JOB ID>02.yaml

if [[ "<PROVISION APP>" == "True" ]]; then
    # Use CDN for WAF policy since failover not published yet
    /usr/bin/yq e ".extension_services.service_operations.[2].value.Tenant_1.Shared.Custom_WAF_Policy.url = \"https://cdn.f5.com/product/cloudsolutions/solution-scripts/Rapid_Deployment_Policy_13_1.xml\"" -i <DEWPOINT JOB ID>01.yaml
    /usr/bin/yq e ".extension_services.service_operations.[2].value.Tenant_1.Shared.Custom_WAF_Policy.url = \"https://cdn.f5.com/product/cloudsolutions/solution-scripts/Rapid_Deployment_Policy_13_1.xml\"" -i <DEWPOINT JOB ID>02.yaml
fi

# print out config files
/usr/bin/yq e <DEWPOINT JOB ID>01.yaml
/usr/bin/yq e <DEWPOINT JOB ID>02.yaml

CONFIG_RESULT_01=$(az storage blob upload -f <DEWPOINT JOB ID>01.yaml --account-name ${STORAGE_ACCOUNT_NAME} -c templates -n <DEWPOINT JOB ID>01.yaml)
CONFIG_RESULT_02=$(az storage blob upload -f <DEWPOINT JOB ID>02.yaml --account-name ${STORAGE_ACCOUNT_NAME} -c templates -n <DEWPOINT JOB ID>02.yaml)

RUNTIME_CONFIG_URL_01=${STORAGE_ACCOUNT_FQDN}templates/<DEWPOINT JOB ID>01.yaml
RUNTIME_CONFIG_URL_02=${STORAGE_ACCOUNT_FQDN}templates/<DEWPOINT JOB ID>02.yaml

DEPLOY_PARAMS='{"templateBaseUrl":{"value":"'"${STORAGE_ACCOUNT_FQDN}"'"},"artifactLocation":{"value":"<ARTIFACT LOCATION>"},"allowUsageAnalytics":{"value":False},"uniqueString":{"value":"<RESOURCE GROUP>"},"provisionPublicIpMgmt":{"value":<PROVISION PUBLIC IP>},"sshKey":{"value":"'"${SSH_KEY}"'"},"bigIpInstanceType":{"value":"<INSTANCE TYPE>"},"bigIpImage":{"value":"<IMAGE>"},"bigIpLicenseKey01":{"value":"'"${LIC_KEY_1}"'"},"bigIpLicenseKey02":{"value":"'"${LIC_KEY_2}"'"},"restrictedSrcAddressMgmt":{"value":"'"${SRC_IP}"'"},"numNics":{"value":<NIC COUNT>},"restrictedSrcAddressApp":{"value":"'"${SRC_IP}"'"},"useAvailabilityZones":{"value":<USE AVAILABILITY ZONES>},"bigIpPasswordSecretId":{"value":"'"${SECRET_ID}"'"},"bigIpPasswordSecretValue":{"value":"'"${SECRET_VALUE}"'"},"provisionServicePublicIp":{"value":<PROVISION APP>},"bigIpMgmtSubnetId":{"value":"'"${MGMT_SUBNET_ID}"'"},"bigIpExternalSubnetId":{"value":"'"${EXT_SUBNET_ID}"'"},"bigIpInternalSubnetId":{"value":"'"${INT_SUBNET_ID}"'"},"bigIpExternalSelfIp01":{"value":"<SELF EXT 1>"},"bigIpExternalSelfIp02":{"value":"<SELF EXT 2>"},"bigIpInternalSelfIp01":{"value":"<SELF INT 1>"},"bigIpInternalSelfIp02":{"value":"<SELF INT 2>"},"bigIpMgmtAddress01":{"value":"<SELF MGMT 1>"},"bigIpMgmtAddress02":{"value":"<SELF MGMT 2>"},"bigIpExternalVip01":{"value":"<EXT VIP ADDRESS>"},"cfeStorageAccountName":{"value":"<DEWPOINT JOB ID>stcfe"},"cfeTag":{"value":"<CFE TAG>"},"bigIpRuntimeInitConfig01":{"value":"'"${RUNTIME_CONFIG_URL_01}"'"},"bigIpRuntimeInitConfig02":{"value":"'"${RUNTIME_CONFIG_URL_02}"'"},"bigIpUserAssignManagedIdentity":{"value":"'"${IDENTITY}"'"}}'

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
