#!/usr/bin/env bash
#  expectValue = "VMSS SETTINGS PASSED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 5

# Script Requires min BASH Version 4
# usage: verify_insight_resource associative_array
# Array: [rule]="expected_value"
function verify_vmss_resource() {
    local -n _arr=$1
    local vmss_resource_object=$(az vmss show --name dd-vmss-<DEWPOINT JOB ID> --resource-group <RESOURCE GROUP> | jq -r .)
    for r in "${!_arr[@]}";
    do
        local response=$(echo ${vmss_resource_object} | jq -r .$r)
        if echo "$response" | grep -q "${_arr[$r]}"; then
            rule_result="Rule:${r}    Response:$response   Value:${_arr[$r]}    PASSED"
        else
            rule_result="Rule:${r}    Response:$response   Value:${_arr[$r]}    FAILED"
        fi
        spacer=$'\n============\n'
        local results="${results}${rule_result}${spacer}"
    done
    echo "$results"
}

# Build associative security group arrays
# array_name[jq_filter]=expected_response
declare -A vmss_settings
# setup identity type being used and verify
if [ "<USE ROLE DEFINITION ID>" == "Yes" ] && [ "<USER ASSIGN MANAGED IDENTITY>" == "No" ]; then
    identity_type="SystemAssigned"
    vmss_settings[identity.type]="${identity_type}"
elif [ "<USE ROLE DEFINITION ID>" == "No" ] && [ "<USER ASSIGN MANAGED IDENTITY>" == "No" ]; then
    echo "Skip test, identity not used."
elif [[ "<USE ROLE DEFINITION ID>" == "No" ]]; then
    identity_type="UserAssigned"
    vmss_settings[identity.type]="${identity_type}"
else
    identity_type="SystemAssigned, UserAssigned"
    vmss_settings[identity.type]="${identity_type}"
fi

# verify user assigned managged identitiy if used
if [[ "<USER ASSIGN MANAGED IDENTITY>" == "Yes" ]]; then
    assigned_user_identity="$(az deployment group show -n <RESOURCE GROUP>-access-env -g <RESOURCE GROUP> | jq  -r .properties.outputs.userAssignedIdentityId.value)"
    vmss_settings[identity.userAssignedIdentities]="${assigned_user_identity}"
elif [[ "<USER ASSIGN MANAGED IDENTITY>" == "No" ]]; then
    echo "user identity not used"
else
    vmss_settings[identity.userAssignedIdentities]="<USER ASSIGN MANAGED IDENTITY>"
fi

# verify command to execute has simplified setup script
vmss_settings[virtualMachineProfile.extensionProfile.extensions\[\].settings.commandToExecute]="base64 -d /var/lib/waagent/CustomData | bash"

# verify load balancer backend address pools based network.json environmental setup
if [ <NUMBER PUBLIC MGMT IP ADDRESSES> = 0 ] && [ "<INTERNAL LOAD BALANCER NAME>" != "none" ]; then
    ext_backend_pool="$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq -r .properties.outputs.externalBackEndLoadBalancerId.value)"
    int_backend_pool="$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq -r .properties.outputs.internalBackEndLoadBalancerId.value)"
    vmss_settings[virtualMachineProfile.networkProfile.networkInterfaceConfigurations\[\].ipConfigurations\[\].loadBalancerBackendAddressPools\[\].id]="${int_backend_pool}"
elif [ <NUMBER PUBLIC MGMT IP ADDRESSES> != 0 ] && [ "<INTERNAL LOAD BALANCER NAME>" != "none" ]; then
    ext_backend_pool="$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq -r .properties.outputs.externalBackEndLoadBalancerId.value)"
    int_backend_pool="$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq -r .properties.outputs.internalBackEndLoadBalancerId.value)"
    mgmt_backend_pool="$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq -r .properties.outputs.externalBackEndMgmtLoadBalancerId.value)"
    vmss_settings[virtualMachineProfile.networkProfile.networkInterfaceConfigurations\[\].ipConfigurations\[\].loadBalancerBackendAddressPools\[\].id]="${mgmt_backend_pool}"
    vmss_settings[virtualMachineProfile.networkProfile.networkInterfaceConfigurations\[\].ipConfigurations\[\].loadBalancerBackendAddressPools\[\].id]="${int_backend_pool}"
elif [ <NUMBER PUBLIC MGMT IP ADDRESSES> != 0 ] && [ "<INTERNAL LOAD BALANCER NAME>" == "none" ]; then
    ext_backend_pool="$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq -r .properties.outputs.externalBackEndLoadBalancerId.value)"
    mgmt_backend_pool="$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq -r .properties.outputs.externalBackEndMgmtLoadBalancerId.value)"
    vmss_settings[virtualMachineProfile.networkProfile.networkInterfaceConfigurations\[\].ipConfigurations\[\].loadBalancerBackendAddressPools\[\].id]="${mgmt_backend_pool}"
else
    ext_backend_pool="$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq -r .properties.outputs.externalBackEndLoadBalancerId.value)"
fi
vmss_settings[virtualMachineProfile.networkProfile.networkInterfaceConfigurations\[\].ipConfigurations\[\].loadBalancerBackendAddressPools\[\].id]="${ext_backend_pool}"

# verify natpools if being used
if [[ "<USE NAT POOLS>" == "Yes" ]]; then
    inbound_mgmt_nat_pool="$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq -r .properties.outputs.inboundMgmtNatPool.value)"
    inbound_ssh_nat_pool="$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq -r .properties.outputs.inboundSshNatPool.value)"
    vmss_settings[virtualMachineProfile.networkProfile.networkInterfaceConfigurations\[\].ipConfigurations\[\].loadBalancerInboundNatPools\[\].id]="${inbound_mgmt_nat_pool}"
    vmss_settings[virtualMachineProfile.networkProfile.networkInterfaceConfigurations\[\].ipConfigurations\[\].loadBalancerInboundNatPools\[\].id]="${inbound_ssh_nat_pool}"
else
    echo "inbound nat pool not being used"
fi

# verify upgrade policy and health probe ID
if [[ "<USE ROLLING UPGRADE>" == "Yes" ]] && [ "<EXTERNAL LOAD BALANCER NAME>" != "none" ]; then
    health_probe_id="$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq -r .properties.outputs.externalLoadBalancerProbesId.value[0])"
    upgrade_policy="Rolling"
    vmss_settings[virtualMachineProfile.networkProfile.healthProbe.id]="${health_probe_id}"
    vmss_settings[upgradePolicy.mode]="${upgrade_policy}"
    vmss_settings[upgradePolicy.rollingUpgradePolicy.maxBatchInstancePercent]=<UPGRADE MAX BATCH>
    vmss_settings[upgradePolicy.rollingUpgradePolicy.maxUnhealthyInstancePercent]=<UPGRADE MAX UNHEALTHY>
    vmss_settings[upgradePolicy.rollingUpgradePolicy.maxUnhealthyUpgradedInstancePercent]=<UPGRADE MAX UNHEALTHY UPGRADED>
    vmss_settings[upgradePolicy.rollingUpgradePolicy.pauseTimeBetweenBatches]="PT<UPGRADE PAUSE TIME>S"
else
    upgrade_policy="Manual"
    vmss_settings[upgradePolicy.mode]="${upgrade_policy}"
fi

# verify public ip config if used
if [[ '<PROVISION PUBLIC IP>' == *"name"* ]] ; then
    name=$(echo '<PROVISION PUBLIC IP>' | jq -r .name)
    vmss_settings[virtualMachineProfile.networkProfile.networkInterfaceConfigurations\[\].ipConfigurations\[\].publicIpAddressConfiguration.name]="${name}"
    timeout=$(echo '<PROVISION PUBLIC IP>' | jq -r .properties.idleTimeoutInMinutes)
    vmss_settings[virtualMachineProfile.networkProfile.networkInterfaceConfigurations\[\].ipConfigurations\[\].publicIpAddressConfiguration.idleTimeoutInMinutes]="${timeout}"
else
    echo "public ip not provisioned"
fi

# verify subnet based on network.json settings
subnet="$(az deployment group show -n <RESOURCE GROUP>-net-env -g <RESOURCE GROUP> | jq  -r .properties.outputs.subnets.value[0])"
vmss_settings[virtualMachineProfile.networkProfile.networkInterfaceConfigurations\[\].ipConfigurations\[\].subnet.id]="${subnet}"

# verify nsg based on dag.json settings
nsg="$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq  -r .properties.outputs.nsg0Id.value)"
vmss_settings[virtualMachineProfile.networkProfile.networkInterfaceConfigurations\[\].networkSecurityGroup.id]="${nsg}"

# verify username assignment
vmss_settings[virtualMachineProfile.osProfile.adminUsername]="<ADMIN USERNAME>"

# verify vmss name
vmss_settings[virtualMachineProfile.osProfile.computerNamePrefix]="<VMSS NAME>"

# verify ssh key set
vmss_settings[virtualMachineProfile.osProfile.linuxConfiguration.ssh.publicKeys[].keyData]="BEGIN SSH2 PUBLIC KEY"

# verify image based on urn or id
if [[ "<IMAGE>" == *"Microsoft.Compute"* ]]; then
    vmss_settings[virtualMachineProfile.storageProfile.imageReference.id]="<IMAGE>"
else
    IFS=':' read -r -a image_ref <<< "<IMAGE>"
    vmss_settings[virtualMachineProfile.storageProfile.imageReference.publisher]="${image_ref[0]}"
    vmss_settings[virtualMachineProfile.storageProfile.imageReference.offer]="${image_ref[1]}"
    vmss_settings[virtualMachineProfile.storageProfile.imageReference.sku]="${image_ref[2]}"
    vmss_settings[virtualMachineProfile.storageProfile.imageReference.version]="${image_ref[3]}"
fi

# verify capacity settings
vmss_settings[sku.capacity]="<VM SCALE SET MIN COUNT>"
vmss_settings[sku.name]="<INSTANCE TYPE>"

# verify az setting
if [[ "<USE AVAILABILITY ZONES>" == "Yes" ]]; then
    vmss_settings[zones[0]]="1"
fi

# verify vmss id output
id=$(az deployment group show -n <RESOURCE GROUP> -g <RESOURCE GROUP> | jq -r .properties.outputs.vmssId.value)
vmss_settings[id]="${id}"

# Run arrays through function
response=$(verify_vmss_resource "vmss_settings")
spacer=$'\n============\n'

# Evaluate results
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "VMSS SETTINGS PASSED ${spacer}${response}"
fi