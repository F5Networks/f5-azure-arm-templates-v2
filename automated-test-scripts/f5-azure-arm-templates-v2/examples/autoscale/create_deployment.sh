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

BIGIQ_ADDRESS=''
SECRET_ID=''
BIGIQ_PARAMS=''
if [[ "<LICENSE TYPE>" == "bigiq" ]]; then
    if [ -f "${TMP_DIR}/bigiq_info.json" ]; then
        echo "Found existing BIG-IQ"
        cat ${TMP_DIR}/bigiq_info.json
        bigiq_stack_name=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_stack_name)
        bigiq_stack_region=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_stack_region)
        bigiq_address=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_address)
    else
        echo "Template validation failed - No BIG-IQ found"
    fi

    BIGIQ_ADDRESS=$bigiq_address
    SECRET_ID=$(az keyvault secret show --vault-name <RESOURCE GROUP>fv -n <RESOURCE GROUP>bigiq | jq .id --raw-output)
    BIGIQ_PARAMS=',"bigIqVnetId":{"value":""},"secretId":{"value":"'"${SECRET_ID}"'"}'
fi

WORKSPACE_ID='WORKSPACE_ID'
if [[ "<CREATE WORKSPACE>" == "False" ]]; then
    WORKSPACE_ID=$(az monitor log-analytics workspace show --resource-group <RESOURCE GROUP> --workspace-name <RESOURCE GROUP>-log-wrkspc --query customerId | tr -d '"')
fi

## Create runtime configs with yq
cp /$PWD/examples/autoscale/bigip-configurations/runtime-init-conf-<LICENSE TYPE>-with-app.yaml <DEWPOINT JOB ID>.yaml
/usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.class = \"User\"" -i <DEWPOINT JOB ID>.yaml
/usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.password = \"<SECRET VALUE>\"" -i <DEWPOINT JOB ID>.yaml
/usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.shell = \"bash\"" -i <DEWPOINT JOB ID>.yaml
/usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.userType = \"regular\"" -i <DEWPOINT JOB ID>.yaml
/usr/bin/yq e ".extension_services.service_operations.[1].value.Tenant_1.Shared.Custom_WAF_Policy.enforcementMode = \"blocking\"" -i <DEWPOINT JOB ID>.yaml
/usr/bin/yq e ".extension_services.service_operations.[1].value.Tenant_1.Shared.Custom_WAF_Policy.url = \"https://cdn.f5.com/product/cloudsolutions/solution-scripts/Rapid_Deployment_Policy_13_1.xml\"" -i <DEWPOINT JOB ID>.yaml

if [[ "<LICENSE TYPE>" == "bigiq" ]]; then
    /usr/bin/yq e ".runtime_parameters.[5].secretProvider.vaultUrl = \"https://<RESOURCE GROUP>fv.vault.azure.net/\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".runtime_parameters.[5].secretProvider.secretId = \"<RESOURCE GROUP>bigiq\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.My_License.bigIqHost = \"${BIGIQ_ADDRESS}\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.My_License.bigIqUsername = \"admin\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.My_License.licensePool = \"production\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.My_License.tenant = \"<DEWPOINT JOB ID>\"" -i <DEWPOINT JOB ID>.yaml
fi

cp <DEWPOINT JOB ID>.yaml update_<DEWPOINT JOB ID>.yaml
/usr/bin/yq e ".extension_services.service_operations.[1].value.Tenant_1.Shared.Custom_WAF_Policy.enforcementMode = \"transparent\"" -i update_<DEWPOINT JOB ID>.yaml

## Upload templates and configs to container
CONFIG_RESULT=$(az storage blob upload -f <DEWPOINT JOB ID>.yaml --account-name ${STORAGE_ACCOUNT_NAME} -c templates -n <DEWPOINT JOB ID>.yaml)
CONFIG_UPDATE_RESULT=$(az storage blob upload -f update_<DEWPOINT JOB ID>.yaml --account-name ${STORAGE_ACCOUNT_NAME} -c templates -n update_<DEWPOINT JOB ID>.yaml)
RUNTIME_CONFIG_URL=${STORAGE_ACCOUNT_FQDN}templates/<DEWPOINT JOB ID>.yaml

if [[ <USE DEFAULT PARAMETERS> == 'Yes' ]]; then
   DEPLOY_PARAMS='{"secretId":{"value":"'"${SECRET_ID}"'"},"uniqueString":{"value":"<RESOURCE GROUP>"},"sshKey":{"value":"'"${SSH_KEY}"'"},"restrictedSrcAddressApp":{"value":"<RESTRICTED SRC ADDRESS APP>"},"restrictedSrcAddressMgmt":{"value":"<RESTRICTED SRC ADDRESS>"},'${BIGIQ_PARAMS}'}'
else
    if [[ -z <BIGIP RUNTIME INIT PACKAGEURL> ]]; then
        DEPLOY_PARAMS='{"templateBaseUrl":{"value":"'"${STORAGE_ACCOUNT_FQDN}"'"},"artifactLocation":{"value":"<ARTIFACT LOCATION>"},"createWorkspace":{"value":<CREATE WORKSPACE>},"uniqueString":{"value":"<RESOURCE GROUP>"},"workspaceId":{"value":"'"${WORKSPACE_ID}"'"},"sshKey":{"value":"'"${SSH_KEY}"'"},"appContainerName":{"value":"<APP CONTAINER>"},"restrictedSrcAddressApp":{"value":"<RESTRICTED SRC ADDRESS APP>"},"restrictedSrcAddressMgmt":{"value":"<RESTRICTED SRC ADDRESS>"},"bigIpImage":{"value":"<IMAGE>"},"bigIpInstanceType":{"value":"<INSTANCE TYPE>"},"bigIpRuntimeInitConfig":{"value":"'"${RUNTIME_CONFIG_URL}"'"},"bigIpScalingMaxSize":{"value":<SCALING MAX>},"bigIpScalingMinSize":{"value":<SCALING MIN>},"bigIpScaleOutCpuThreshold":{"value":<SCALE OUT CPU THRESHOLD>},"bigIpScaleInCpuThreshold":{"value":<SCALE IN CPU THRESHOLD>},"bigIpScaleOutTimeWindow":{"value":<SCALE OUT TIME WINDOW>},"bigIpScaleInTimeWindow":{"value":<SCALE IN TIME WINDOW>},"bigIpScaleOutThroughputThreshold":{"value":<SCALE OUT THROUGHPUT THRESHOLD>},"bigIpScaleInThroughputThreshold":{"value":<SCALE IN THROUGHPUT THRESHOLD>},"appScalingMinSize":{"value":<APP VM SCALE SET MIN COUNT>},"appScalingMaxSize":{"value":<APP VM SCALE SET MAX COUNT>},"bigIpMaxBatchInstancePercent":{"value":<UPGRADE MAX BATCH>},"bigIpMaxUnhealthyInstancePercent":{"value":<UPGRADE MAX UNHEALTHY>},"bigIpMaxUnhealthyUpgradedInstancePercent":{"value":<UPGRADE MAX UNHEALTHY UPGRADED>},"bigIpPauseTimeBetweenBatches":{"value":<UPGRADE PAUSE TIME>},"provisionPublicIp":{"value":<PROVISION PUBLIC IP>},"provisionExternalBigIpLoadBalancer":{"value":<PROVISION EXTERNAL LB>},"provisionInternalBigIpLoadBalancer":{"value":<PROVISION INTERNAL LB>},"useAvailabilityZones":{"value":<USE AVAILABILITY ZONES>}'${BIGIQ_PARAMS}'}'
    else
        DEPLOY_PARAMS='{"templateBaseUrl":{"value":"'"${STORAGE_ACCOUNT_FQDN}"'"},"artifactLocation":{"value":"<ARTIFACT LOCATION>"},"createWorkspace":{"value":<CREATE WORKSPACE>},"uniqueString":{"value":"<RESOURCE GROUP>"},"workspaceId":{"value":"'"${WORKSPACE_ID}"'"},"sshKey":{"value":"'"${SSH_KEY}"'"},"appContainerName":{"value":"<APP CONTAINER>"},"restrictedSrcAddressApp":{"value":"<RESTRICTED SRC ADDRESS APP>"},"restrictedSrcAddressMgmt":{"value":"<RESTRICTED SRC ADDRESS>"},"bigIpImage":{"value":"<IMAGE>"},"bigIpInstanceType":{"value":"<INSTANCE TYPE>"},"bigIpRuntimeInitConfig":{"value":"'"${RUNTIME_CONFIG_URL}"'"},"bigIpRuntimeInitPackageUrl":{"value":"<BIGIP RUNTIME INIT PACKAGEURL>"},"bigIpScalingMaxSize":{"value":<SCALING MAX>},"bigIpScalingMinSize":{"value":<SCALING MIN>},"bigIpScaleOutCpuThreshold":{"value":<SCALE OUT CPU THRESHOLD>},"bigIpScaleInCpuThreshold":{"value":<SCALE IN CPU THRESHOLD>},"bigIpScaleOutTimeWindow":{"value":<SCALE OUT TIME WINDOW>},"bigIpScaleInTimeWindow":{"value":<SCALE IN TIME WINDOW>},"bigIpScaleOutThroughputThreshold":{"value":<SCALE OUT THROUGHPUT THRESHOLD>},"bigIpScaleInThroughputThreshold":{"value":<SCALE IN THROUGHPUT THRESHOLD>},"appScalingMinSize":{"value":<APP VM SCALE SET MIN COUNT>},"appScalingMaxSize":{"value":<APP VM SCALE SET MAX COUNT>},"bigIpMaxBatchInstancePercent":{"value":<UPGRADE MAX BATCH>},"bigIpMaxUnhealthyInstancePercent":{"value":<UPGRADE MAX UNHEALTHY>},"bigIpMaxUnhealthyUpgradedInstancePercent":{"value":<UPGRADE MAX UNHEALTHY UPGRADED>},"bigIpPauseTimeBetweenBatches":{"value":<UPGRADE PAUSE TIME>},"provisionPublicIp":{"value":<PROVISION PUBLIC IP>},"provisionExternalBigIpLoadBalancer":{"value":<PROVISION EXTERNAL LB>},"provisionInternalBigIpLoadBalancer":{"value":<PROVISION INTERNAL LB>},"useAvailabilityZones":{"value":<USE AVAILABILITY ZONES>}'${BIGIQ_PARAMS}'}'
    fi
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
