#!/usr/bin/env bash
#  expectValue = "OUTPUTS PASSED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10

# Script Requires min BASH Version 4
# usage: verify_outputs associative_array
# Array: [rule]="expected_value"
function verify_outputs() {
    local -n _arr=$1
    local outputs_object=$(az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP> | jq -r '.properties.outputs')
    for r in "${!_arr[@]}";
    do
        local response=$(echo ${outputs_object} | jq -r .$r)
        if echo "$response" | grep -q "${_arr[$r]}"; then
            rule_result="Rule:${r}    Response:$response    Value:${_arr[$r]}    PASSED"
        else
            rule_result="Rule:${r}    Response:$response    Value:${_arr[$r]}    FAILED"
        fi
        spacer=$'\n============\n'
        local results="${results}${rule_result}${spacer}"
    done
    echo "$results"
}

# Build associative array
# array_name[jq_filter]=expected_response
subscription=$(az account show | jq -r .id)
mgmt_private_ip="10.0.0.11"
id=$(az vm show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bigip-vm | jq -r .vmId)

if [[ <NIC COUNT> -eq 1 ]]; then
    mgmt_port="8443"
    nic1_service_index="0"
    nic2_service_index="0"
    vip_1_public_ip=$(az vm list-ip-addresses -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bigip-vm | jq -r .[0].virtualMachine.network.publicIpAddresses[1].ipAddress)
else
    mgmt_port="443"
    nic1_service_index="1"
    nic2_service_index="2"
    vip_1_public_ip=$(az vm list-ip-addresses -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bigip-vm | jq -r .[1].virtualMachine.network.publicIpAddresses[1].ipAddress)
fi

vip_1_private_ip="10.0.${nic1_service_index}.101"

declare -A outputs
outputs[appPrivateIp]="10.0.<NIC COUNT>.4"
outputs[appUsername]="azureuser"
outputs[appVmName]="<RESOURCE GROUP>-app-vm"
outputs[bigIpManagementPrivateIp]=$mgmt_private_ip
outputs[bigIpManagementPrivateUrl]="https://${mgmt_private_ip}:${mgmt_port}/"

if [[ <PROVISION PUBLIC IP> == True ]]; then
    mgmt_public_ip=$(az vm list-ip-addresses -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bigip-vm | jq -r .[0].virtualMachine.network.publicIpAddresses[0].ipAddress)
    outputs[bigIpManagementPublicIp]=$mgmt_public_ip
    outputs[bigIpManagementPublicUrl]="https://${mgmt_public_ip}:${mgmt_port}/"
fi

outputs[vip1PrivateIp]=$vip_1_private_ip
outputs[vip1PrivateUrlHttp]="http://${vip_1_private_ip}/"
outputs[vip1PrivateUrlHttps]="https://${vip_1_private_ip}/"
outputs[vip1PublicIp]=$vip_1_public_ip
outputs[vip1PublicUrlHttp]="http://${vip_1_public_ip}/"
outputs[vip1PublicUrlHttps]="https://${vip_1_public_ip}/"
outputs[virtualNetworkId]="/subscriptions/${subscription}/resourceGroups/<RESOURCE GROUP>/providers/Microsoft.Network/virtualNetworks/<RESOURCE GROUP>-vnet"
outputs[bigIpVmId]="${id}"

# Run array through function
response=$(verify_outputs "outputs")
spacer=$'\n============\n'

# Evaluate results
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "OUTPUTS PASSED ${spacer}${response}"
fi
