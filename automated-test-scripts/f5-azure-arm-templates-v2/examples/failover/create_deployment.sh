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

SECRET_ID=$(az keyvault secret show --vault-name <RESOURCE GROUP>fv -n <RESOURCE GROUP>bigiq | jq .id --raw-output)
echo $SECRET_ID

## Create runtime configs with yq
if [[ "<PROVISION APP>" == "False" ]]; then
    cp /$PWD/examples/failover/bigip-configurations/runtime-init-conf-3nic-<LICENSE TYPE>-instance01.yaml <DEWPOINT JOB ID>01.yaml
    cp /$PWD/examples/failover/bigip-configurations/runtime-init-conf-3nic-<LICENSE TYPE>-instance02.yaml <DEWPOINT JOB ID>02.yaml
    do_index=2
else
    cp /$PWD/examples/failover/bigip-configurations/runtime-init-conf-3nic-<LICENSE TYPE>-instance01-with-app.yaml <DEWPOINT JOB ID>01.yaml
    cp /$PWD/examples/failover/bigip-configurations/runtime-init-conf-3nic-<LICENSE TYPE>-instance02-with-app.yaml <DEWPOINT JOB ID>02.yaml
    do_index=3
fi

# Set log level
/usr/bin/yq e ".controls.logLevel = \"<LOG LEVEL>\"" -i <DEWPOINT JOB ID>01.yaml
/usr/bin/yq e ".controls.logLevel = \"<LOG LEVEL>\"" -i <DEWPOINT JOB ID>02.yaml

# Runtime parameters
/usr/bin/yq e ".runtime_parameters.[0].secretProvider.vaultUrl = \"https://<RESOURCE GROUP>fv.vault.azure.net/\"" -i <DEWPOINT JOB ID>01.yaml
/usr/bin/yq e ".runtime_parameters.[0].secretProvider.vaultUrl = \"https://<RESOURCE GROUP>fv.vault.azure.net/\"" -i <DEWPOINT JOB ID>02.yaml
/usr/bin/yq e ".runtime_parameters.[0].secretProvider.secretId = \"<RESOURCE GROUP>bigiq\"" -i <DEWPOINT JOB ID>01.yaml
/usr/bin/yq e ".runtime_parameters.[0].secretProvider.secretId = \"<RESOURCE GROUP>bigiq\"" -i <DEWPOINT JOB ID>02.yaml

# Disable AutoPhoneHome
/usr/bin/yq e ".extension_services.service_operations.[0].value.Common.My_System.autoPhonehome = false" -i <DEWPOINT JOB ID>01.yaml
/usr/bin/yq e ".extension_services.service_operations.[0].value.Common.My_System.autoPhonehome = false" -i <DEWPOINT JOB ID>02.yaml

/usr/bin/yq e ".extension_services.service_operations.[${do_index}].value.Common.My_System.autoPhonehome = false" -i <DEWPOINT JOB ID>01.yaml
/usr/bin/yq e ".extension_services.service_operations.[${do_index}].value.Common.My_System.autoPhonehome = false" -i <DEWPOINT JOB ID>02.yaml

# Add BYOL license to declarations
if [[ <LICENSE TYPE> == "byol" ]]; then
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.My_License.regKey = \"<AUTOFILL EVAL LICENSE KEY>\"" -i <DEWPOINT JOB ID>01.yaml
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.My_License.regKey = \"<AUTOFILL EVAL LICENSE KEY 2>\"" -i <DEWPOINT JOB ID>02.yaml
fi

# Update cfe tag
/usr/bin/yq e ".extension_services.service_operations.[1].value.externalStorage.scopingTags.f5_cloud_failover_label = \"<RESOURCE GROUP>\"" -i <DEWPOINT JOB ID>01.yaml
/usr/bin/yq e ".extension_services.service_operations.[1].value.externalStorage.scopingTags.f5_cloud_failover_label = \"<RESOURCE GROUP>\"" -i <DEWPOINT JOB ID>02.yaml
/usr/bin/yq e ".extension_services.service_operations.[1].value.failoverAddresses.scopingTags.f5_cloud_failover_label = \"<RESOURCE GROUP>\"" -i <DEWPOINT JOB ID>01.yaml
/usr/bin/yq e ".extension_services.service_operations.[1].value.failoverAddresses.scopingTags.f5_cloud_failover_label = \"<RESOURCE GROUP>\"" -i <DEWPOINT JOB ID>02.yaml

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

if [[ <USE DEFAULT PARAMETERS> == 'Yes' ]]; then
    DEPLOY_PARAMS='{"uniqueString":{"value":"<RESOURCE GROUP>"},"sshKey":{"value":"'"${SSH_KEY}"'"},"restrictedSrcAddressApp":{"value":"<RESTRICTED SRC ADDRESS APP>"},"restrictedSrcAddressMgmt":{"value":"<RESTRICTED SRC ADDRESS>"},"restrictedSrcAddressVip":{"value":"<RESTRICTED SRC ADDRESS APP>"}}'
else
    DEPLOY_PARAMS='{"templateBaseUrl":{"value":"'"${STORAGE_ACCOUNT_FQDN}"'"},"artifactLocation":{"value":"<ARTIFACT LOCATION>"},"uniqueString":{"value":"<RESOURCE GROUP>"},"provisionPublicIp":{"value":<PROVISION PUBLIC IP>},"sshKey":{"value":"'"${SSH_KEY}"'"},"bigIpInstanceType":{"value":"<INSTANCE TYPE>"},"bigIpImage":{"value":"<IMAGE>"},"appContainerName":{"value":"<APP CONTAINER>"},"restrictedSrcAddressApp":{"value":"<RESTRICTED SRC ADDRESS APP>"},"restrictedSrcAddressMgmt":{"value":"<RESTRICTED SRC ADDRESS>"},"useAvailabilityZones":{"value":<USE AVAILABILITY ZONES>},"bigIpPasswordSecretId":{"value":"'"${SECRET_ID}"'"},"provisionExampleApp":{"value":<PROVISION APP>},"restrictedSrcAddressVip":{"value":"<RESTRICTED SRC ADDRESS APP>"},"bigIpExternalSelfAddress01":{"value":"<SELF EXT 1>"},"bigIpExternalSelfAddress02":{"value":"<SELF EXT 2>"},"bigIpInternalSelfAddress01":{"value":"<SELF INT 1>"},"bigIpInternalSelfAddress02":{"value":"<SELF INT 2>"},"bigIpMgmtSelfAddress01":{"value":"<SELF MGMT 1>"},"bigIpMgmtSelfAddress02":{"value":"<SELF MGMT 2>"},"cfeStorageAccountName":{"value":"<RESOURCE GROUP>"},"cfeTag":{"value":"<CFE TAG>"},"bigIpRuntimeInitConfig01":{"value":"'"${RUNTIME_CONFIG_URL_01}"'"},"bigIpRuntimeInitConfig02":{"value":"'"${RUNTIME_CONFIG_URL_02}"'"}}'
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
