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

ID=$(az network vnet subnet show --resource-group dd-bigip-<DEWPOINT JOB ID> --name subnet-01 --vnet-name vnet-<DEWPOINT JOB ID> | jq -r .id)
SUBNETID="\"subnetId\":{\"value\":\"${ID}\"},"
SSH_KEY=$(az keyvault secret show --vault-name dewdropKeyVault -n dewpt-public | jq .value --raw-output)
if [[ "<NSG0>" != "{}" ]]; then
    NSGID="\"nsgId\":{\"value\":\"$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq  -r .properties.outputs.nsg0Id.value)\"},"
else
    NSGID=""
fi

# identity section
ASSIGNMANAGEDIDENTITY=""
ROLEDEFINITIONID=""
TEMP_VAR="<USER ASSIGNED IDENT NAME>"
if [[ $TEMP_VAR =~ "USER ASSIGNED IDENT NAME" || -z $TEMP_VAR ]]; then
   ROLEDEFINITIONID="\"roleDefinitionId\":{\"value\":\"$(az deployment group show -n <RESOURCE GROUP>-access-env -g <RESOURCE GROUP> | jq -r .properties.outputs.roleDefinitionId.value)\"},"
else
   ASSIGNMANAGEDIDENTITY="\"userAssignManagedIdentity\":{\"value\":\"$(az deployment group show -n <RESOURCE GROUP>-access-env -g <RESOURCE GROUP> | jq  -r .properties.outputs.userAssignedIdentityId.value)\"},"
fi

if [ <NUMBER PUBLIC MGMT IP ADDRESSES> = 0 ] && [ "<INTERNAL LOAD BALANCER NAME>" != "none" ]; then
    LOADBALANCERBACKENDADDRESSPOOLSARRAY="\"loadBalancerBackendAddressPoolsArray\":{\"value\":[{\"id\":\"$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq -r .properties.outputs.externalBackEndLoadBalancerId.value)\"},{\"id\":\"$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq -r .properties.outputs.internalBackEndLoadBalancerId.value)\"}]}"
elif [ <NUMBER PUBLIC MGMT IP ADDRESSES> != 0 ] && [ "<INTERNAL LOAD BALANCER NAME>" != "none" ]; then
    LOADBALANCERBACKENDADDRESSPOOLSARRAY="\"loadBalancerBackendAddressPoolsArray\":{\"value\":[{\"id\":\"$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq -r .properties.outputs.externalBackEndLoadBalancerId.value)\"},{\"id\":\"$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq -r .properties.outputs.externalBackEndMgmtLoadBalancerId.value)\"},{\"id\":\"$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq -r .properties.outputs.internalBackEndLoadBalancerId.value)\"}]}"
elif [ <NUMBER PUBLIC MGMT IP ADDRESSES> != 0 ] && [ "<INTERNAL LOAD BALANCER NAME>" == "none" ]; then
    LOADBALANCERBACKENDADDRESSPOOLSARRAY="\"loadBalancerBackendAddressPoolsArray\":{\"value\":[{\"id\":\"$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq -r .properties.outputs.externalBackEndLoadBalancerId.value)\"},{\"id\":\"$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq -r .properties.outputs.externalBackEndMgmtLoadBalancerId.value)\"}]}"
else
    LOADBALANCERBACKENDADDRESSPOOLSARRAY="\"loadBalancerBackendAddressPoolsArray\":{\"value\":[{\"id\":\"$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq -r .properties.outputs.externalBackEndLoadBalancerId.value)\"}]}"
fi

if [[ "<USE NAT POOLS>" == "Yes" ]]; then
    INBOUNDMGMTNATPOOLID="\"inboundMgmtNatPoolId\":{\"value\":\"$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq -r .properties.outputs.inboundMgmtNatPool.value)\"},"
    INBOUNDSSHNATPOOLID="\"inboundSshNatPoolId\":{\"value\":\"$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq -r .properties.outputs.inboundSshNatPool.value)\"},"
else
    INBOUNDMGMTNATPOOLID=""
    INBOUNDSSHNATPOOLID=""
fi

if [[ "<USE ROLLING UPGRADE>" == "Yes" ]] && [ "<EXTERNAL LOAD BALANCER NAME>" != "none" ]; then
    INSTANCEHEALTHPROBEID="\"instanceHealthProbeId\":{\"value\":\"$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq -r .properties.outputs.externalLoadBalancerProbesId.value[0])\"},"
    ROLLINGUPGRADESETTINGS="\"maxBatchInstancePercent\":{\"value\":<UPGRADE MAX BATCH>},\"maxUnhealthyInstancePercent\":{\"value\":<UPGRADE MAX UNHEALTHY>},\"maxUnhealthyUpgradedInstancePercent\":{\"value\":<UPGRADE MAX UNHEALTHY UPGRADED>},\"pauseTimeBetweenBatches\":{\"value\":<UPGRADE PAUSE TIME>},"
else
    INSTANCEHEALTHPROBEID=""
    ROLLINGUPGRADESETTINGS=""
fi

WORKSPACE_ID=$(az monitor log-analytics workspace show --resource-group <RESOURCE GROUP> --workspace-name f5telemetry --query customerId | tr -d '"')

DEPLOY_PARAMS='{"uniqueString":{"value":"<DNSLABEL>"},"workspaceId":{"value":"'"${WORKSPACE_ID}"'"}, "adminUsername":{"value":"<ADMIN USERNAME>"},"customAutoscaleRules":{"value":<CUSTOM AUTOSCALE RULES>},"provisionPublicIp":{"value":<PROVISION PUBLIC IP>},"sshKey":{"value":"'"$SSH_KEY"'"},"image":{"value":"<IMAGE>"},"instanceType":{"value":"<INSTANCE TYPE>"},"useAvailabilityZones":{"value":<USE AVAILABILITY ZONES>},"bigIpRuntimeInitConfig":{"value":"<RUNTIME CONFIG>"},"vmssName":{"value":"<VMSS NAME>"},"vmScaleSetMinCount":{"value":<VM SCALE SET MIN COUNT>},"vmScaleSetMaxCount":{"value":<VM SCALE SET MAX COUNT>},"cpuMetricName":{"value":"<CPU METRIC NAME>"},"scaleOutCpuThreshold":{"value":<SCALE OUT CPU THRESHOLD>},"scaleInCpuThreshold":{"value":<SCALE IN CPU THRESHOLD>},"scaleOutTimeWindow":{"value":<SCALE OUT TIME WINDOW>},"scaleInTimeWindow":{"value":<SCALE IN TIME WINDOW>},"throughputMetricName":{"value":"<THROUGHPUT METRIC NAME>"},"scaleOutThroughputThreshold":{"value":<SCALE OUT THROUGHPUT THRESHOLD>},"appInsights":{"value":"<APP INSIGHTS>"},"customEmail":{"value":<CUSTOM EMAIL>},"scaleInThroughputThreshold":{"value":<SCALE IN THROUGHPUT THRESHOLD>},'${INBOUNDMGMTNATPOOLID}''${INBOUNDSSHNATPOOLID}''${SUBNETID}''${NSGID}''${ASSIGNMANAGEDIDENTITY}''${ROLEDEFINITIONID}''${INSTANCEHEALTHPROBEID}''${ROLLINGUPGRADESETTINGS}''${LOADBALANCERBACKENDADDRESSPOOLSARRAY}'}'
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
