#!/usr/bin/env bash
#  expectValue = "VM SETTINGS PASSED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 5

# Script Requires min BASH Version 4
# usage: verify_vm_resource associative_array
# Array: [rule]="expected_value"
function verify_vm_resource() {
    local -n _arr=$1
    local vm_resource_object=$(az vm show -d --name dd-vm-<DEWPOINT JOB ID> --resource-group <RESOURCE GROUP> | jq -r .)
    for r in "${!_arr[@]}";
    do
        local response=$(echo ${vm_resource_object} | jq -r .$r)
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
declare -A vm_settings
# setup identity type being used and verify
if [ "<USE ROLE DEFINITION ID>" == "Yes" ] && [ "<USER ASSIGN MANAGED IDENTITY>" == "No" ]; then
    identity_type="SystemAssigned"
    vm_settings[identity.type]="${identity_type}"
elif [ "<USE ROLE DEFINITION ID>" == "No" ] && [ "<USER ASSIGN MANAGED IDENTITY>" == "No" ]; then
    echo "Skip test, identity not used."
elif [[ "<USE ROLE DEFINITION ID>" == "No" ]]; then
    identity_type="UserAssigned"
    vm_settings[identity.type]="${identity_type}"
else
    identity_type="SystemAssigned, UserAssigned"
    vm_settings[identity.type]="${identity_type}"
fi

# verify user assigned managed identity if used
if [[ "<USER ASSIGN MANAGED IDENTITY>" == "Yes" ]]; then
    assigned_user_identity="$(az deployment group show -n <RESOURCE GROUP>-access-env -g <RESOURCE GROUP> | jq  -r .properties.outputs.userAssignedIdentityId.value)"
    vm_settings[identity.userAssignedIdentities]="${assigned_user_identity}"
elif [[ "<USER ASSIGN MANAGED IDENTITY>" == "No" ]]; then
    echo "user identity not used"
else
    vm_settings[identity.userAssignedIdentities]="<USER ASSIGN MANAGED IDENTITY>"
fi

# verify command to execute has simplified setup script
vm_settings[resources\[\].settings.commandToExecute]="base64 -d /var/lib/waagent/customData | bash"
vm_settings[resources\[\].provisioningState]="Succeeded"

# verify number of network interfaces
upperlimit=$((<NUMBER SUBNETS>-1))
for ((s=0; s<=upperlimit; s++));
do
    vm_settings[networkProfile.networkInterfaces\[${s}\].id]="<RESOURCE GROUP>-nic${s}"
done

# verify primary self IPs
test_mgmt_self_ip=(<SELF IP MGMT>)
vm_settings[privateIps]=$test_mgmt_self_ip

# verify username assignment
vm_settings[osProfile.adminUsername]="<ADMIN USERNAME>"

# verify vm name
vm_settings[osProfile.computerName]="<VM NAME>"

# verify ssh key set
vm_settings[osProfile.linuxConfiguration.ssh.publicKeys[].keyData]="BEGIN SSH2 PUBLIC KEY"

# verify image based on urn or id
if [[ "<IMAGE>" == *"Microsoft.Compute"* ]]; then
    vm_settings[storageProfile.imageReference.id]="<IMAGE>"
else
    IFS=':' read -r -a image_ref <<< "<IMAGE>"
    vm_settings[storageProfile.imageReference.publisher]="${image_ref[0]}"
    vm_settings[storageProfile.imageReference.offer]="${image_ref[1]}"
    vm_settings[storageProfile.imageReference.sku]="${image_ref[2]}"
    vm_settings[storageProfile.imageReference.version]="${image_ref[3]}"
fi

# verify az setting
if [[ "<USE AVAILABILITY ZONES>" == "Yes" ]]; then
    vm_settings[zones[0]]="1"
fi

# verify vm id output
id=$(az deployment group show -n <RESOURCE GROUP> -g <RESOURCE GROUP> | jq -r .properties.outputs.vmID.value)
vm_settings[vmId]="${id}"

# Run arrays through function
response=$(verify_vm_resource "vm_settings")
spacer=$'\n============\n'

# Evaluate results
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "VM SETTINGS PASSED ${spacer}${response}"
fi