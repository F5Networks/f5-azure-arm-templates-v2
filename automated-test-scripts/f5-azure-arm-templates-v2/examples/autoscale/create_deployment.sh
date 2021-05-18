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

## Create runtime configs with yq
cp /$PWD/examples/autoscale/bigip-configurations/runtime-init-conf-<LICENSE TYPE>.yaml <DEWPOINT JOB ID>.yaml
/usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.class = \"User\"" -i <DEWPOINT JOB ID>.yaml
/usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.password = \"<SECRET VALUE>\"" -i <DEWPOINT JOB ID>.yaml
/usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.shell = \"bash\"" -i <DEWPOINT JOB ID>.yaml
/usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.userType = \"regular\"" -i <DEWPOINT JOB ID>.yaml
/usr/bin/yq e ".extension_services.service_operations.[1].value.Tenant_1.HTTPS_Service.WAFPolicy.enforcementMode = \"blocking\"" -i <DEWPOINT JOB ID>.yaml
/usr/bin/yq e ".extension_services.service_operations.[1].value.Tenant_1.HTTP_Service.WAFPolicy.enforcementMode = \"blocking\"" -i <DEWPOINT JOB ID>.yaml
/usr/bin/yq e ".extension_services.service_operations.[1].value.Tenant_1.HTTPS_Service.WAFPolicy.url = \"https://raw.githubusercontent.com/f5devcentral/f5-asm-policy-templates/master/generic_ready_template/Rapid_Depolyment_Policy_13_1.xml\"" -i <DEWPOINT JOB ID>.yaml
/usr/bin/yq e ".extension_services.service_operations.[1].value.Tenant_1.HTTP_Service.WAFPolicy.url = \"https://raw.githubusercontent.com/f5devcentral/f5-asm-policy-templates/master/generic_ready_template/Rapid_Depolyment_Policy_13_1.xml\"" -i <DEWPOINT JOB ID>.yaml

if [[ <LICENSE TYPE> == "bigiq" ]]; then
    /usr/bin/yq e ".runtime_parameters.[5].secretProvider.vaultUrl = \"<RESOURCE GROUP>fnfv\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".runtime_parameters.[5].secretProvider.secretId = \"<RESOURCE GROUP>fnbigiq\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.My_License.bigIqHost = \"${BIGIQ_ADDRESS}\"" -i <DEWPOINT JOB ID>.yaml
fi

cp <DEWPOINT JOB ID>.yaml update_<DEWPOINT JOB ID>.yaml
/usr/bin/yq e ".extension_services.service_operations.[1].value.Tenant_1.HTTPS_Service.WAFPolicy.enforcementMode = \"transparent\"" -i update_<DEWPOINT JOB ID>.yaml
/usr/bin/yq e ".extension_services.service_operations.[1].value.Tenant_1.HTTP_Service.WAFPolicy.enforcementMode = \"transparent\"" -i update_<DEWPOINT JOB ID>.yaml

## Upload templates and configs to container
CONFIG_RESULT=$(az storage blob upload -f <DEWPOINT JOB ID>.yaml --account-name ${STORAGE_ACCOUNT_NAME} -c templates -n <DEWPOINT JOB ID>.yaml)
CONFIG_UPDATE_RESULT=$(az storage blob upload -f update_<DEWPOINT JOB ID>.yaml --account-name ${STORAGE_ACCOUNT_NAME} -c templates -n update_<DEWPOINT JOB ID>.yaml)

RUNTIME_CONFIG_URL=${STORAGE_ACCOUNT_FQDN}templates/<DEWPOINT JOB ID>.yaml

WORKSPACE_ID=$(az monitor log-analytics workspace show --resource-group <RESOURCE GROUP> --workspace-name <RESOURCE GROUP>-log-wrkspc --query customerId | tr -d '"')

if [[ -z <BIGIP RUNTIME INIT PACKAGEURL> ]]; then
    DEPLOY_PARAMS='{"templateBaseUrl":{"value":"'"${STORAGE_ACCOUNT_FQDN}"'"},"artifactLocation":{"value":"<ARTIFACT LOCATION>"},"uniqueString":{"value":"<RESOURCE GROUP>"},"workspaceId":{"value":"'"${WORKSPACE_ID}"'"},"sshKey":{"value":"'"${SSH_KEY}"'"},"appContainerName":{"value":"<APP CONTAINER>"},"restrictedSrcAddressApp":{"value":"<RESTRICTED SRC ADDRESS APP>"},"restrictedSrcAddressMgmt":{"value":"<RESTRICTED SRC ADDRESS>"},"bigIpImage":{"value":"<IMAGE>"},"bigIpInstanceType":{"value":"<INSTANCE TYPE>"},"bigIpRuntimeInitConfig":{"value":"'"${RUNTIME_CONFIG_URL}"'"},"bigIpScalingMaxSize":{"value":<SCALING MAX>},"bigIpScalingMinSize":{"value":<SCALING MIN>},"bigIpScaleOutCpuThreshold":{"value":<SCALE OUT CPU THRESHOLD>},"bigIpScaleInCpuThreshold":{"value":<SCALE IN CPU THRESHOLD>},"bigIpScaleOutTimeWindow":{"value":<SCALE OUT TIME WINDOW>},"bigIpScaleInTimeWindow":{"value":<SCALE IN TIME WINDOW>},"bigIpScaleOutThroughputThreshold":{"value":<SCALE OUT THROUGHPUT THRESHOLD>},"bigIpScaleInThroughputThreshold":{"value":<SCALE IN THROUGHPUT THRESHOLD>},"appScalingMinSize":{"value":<APP VM SCALE SET MIN COUNT>},"appScalingMaxSize":{"value":<APP VM SCALE SET MAX COUNT>},"useAvailabilityZones":{"value":<USE AVAILABILITY ZONES>}'${BIGIQ_PARAMS}'}'
else
    DEPLOY_PARAMS='{"templateBaseUrl":{"value":"'"${STORAGE_ACCOUNT_FQDN}"'"},"artifactLocation":{"value":"<ARTIFACT LOCATION>"},"uniqueString":{"value":"<RESOURCE GROUP>"},"workspaceId":{"value":"'"${WORKSPACE_ID}"'"},"sshKey":{"value":"'"${SSH_KEY}"'"},"appContainerName":{"value":"<APP CONTAINER>"},"restrictedSrcAddressApp":{"value":"<RESTRICTED SRC ADDRESS APP>"},"restrictedSrcAddressMgmt":{"value":"<RESTRICTED SRC ADDRESS>"},"bigIpImage":{"value":"<IMAGE>"},"bigIpInstanceType":{"value":"<INSTANCE TYPE>"},"bigIpRuntimeInitConfig":{"value":"'"${RUNTIME_CONFIG_URL}"'"},"bigIpRuntimeInitPackageUrl":{"value":"<BIGIP RUNTIME INIT PACKAGEURL>"},"bigIpScalingMaxSize":{"value":<SCALING MAX>},"bigIpScalingMinSize":{"value":<SCALING MIN>},"bigIpScaleOutCpuThreshold":{"value":<SCALE OUT CPU THRESHOLD>},"bigIpScaleInCpuThreshold":{"value":<SCALE IN CPU THRESHOLD>},"bigIpScaleOutTimeWindow":{"value":<SCALE OUT TIME WINDOW>},"bigIpScaleInTimeWindow":{"value":<SCALE IN TIME WINDOW>},"bigIpScaleOutThroughputThreshold":{"value":<SCALE OUT THROUGHPUT THRESHOLD>},"bigIpScaleInThroughputThreshold":{"value":<SCALE IN THROUGHPUT THRESHOLD>},"appScalingMinSize":{"value":<APP VM SCALE SET MIN COUNT>},"appScalingMaxSize":{"value":<APP VM SCALE SET MAX COUNT>},"useAvailabilityZones":{"value":<USE AVAILABILITY ZONES>}'${BIGIQ_PARAMS}'}'
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
