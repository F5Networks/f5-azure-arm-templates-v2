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
mgmt_private_ip_1="<SELF MGMT 1>"
mgmt_private_ip_2="<SELF MGMT 2>"
id_1=$(az vm show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bigip-vm01 | jq -r .vmId)
id_2=$(az vm show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bigip-vm02 | jq -r .vmId)

mgmt_port="443"
vip_1_private_ip="10.0.1.101"

declare -A outputs

outputs[bigIpInstance01ManagementPrivateIp]=$mgmt_private_ip_1
outputs[bigIpInstance02ManagementPrivateIp]=$mgmt_private_ip_2
outputs[bigIpInstance01ManagementPrivateUrl]="https://${mgmt_private_ip_1}:${mgmt_port}/"
outputs[bigIpInstance02ManagementPrivateUrl]="https://${mgmt_private_ip_2}:${mgmt_port}/"

if [[ <PROVISION PUBLIC IP> == True ]]; then
    mgmt_public_ip_1=$(az vm list-ip-addresses -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bigip-vm01 | jq -r .[0].virtualMachine.network.publicIpAddresses[0].ipAddress)
    mgmt_public_ip_2=$(az vm list-ip-addresses -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bigip-vm02 | jq -r .[0].virtualMachine.network.publicIpAddresses[0].ipAddress)
    outputs[bigIpInstance01ManagementPublicIp]=$mgmt_public_ip_1
    outputs[bigIpInstance01ManagementPublicUrl]="https://${mgmt_public_ip_1}:${mgmt_port}/"
    outputs[bigIpInstance02ManagementPublicIp]=$mgmt_public_ip_2
    outputs[bigIpInstance02ManagementPublicUrl]="https://${mgmt_public_ip_2}:${mgmt_port}/"
fi

if [[ <PROVISION APP> == True ]]; then
    vip_1_public_ip=$(az vm list-ip-addresses -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bigip-vm01 | jq -r .[1].virtualMachine.network.publicIpAddresses[1].ipAddress)
    outputs[vip1PrivateIp]=$vip_1_private_ip
    outputs[vip1PrivateUrlHttp]="http://${vip_1_private_ip}/"
    outputs[vip1PrivateUrlHttps]="https://${vip_1_private_ip}/"
    outputs[vip1PublicIp]=$vip_1_public_ip
    outputs[vip1PublicUrlHttp]="http://${vip_1_public_ip}/"
    outputs[vip1PublicUrlHttps]="https://${vip_1_public_ip}/"
fi

if echo "<TEMPLATE URL>" | grep "azuredeploy.json"; then
    outputs[virtualNetworkId]="/subscriptions/${subscription}/resourceGroups/<RESOURCE GROUP>/providers/Microsoft.Network/virtualNetworks/<RESOURCE GROUP>-vnet"
    if [[ <PROVISION APP> == True ]]; then
        outputs[appPrivateIp]="10.0.3.4"
        outputs[appUsername]="azureuser"
        outputs[appVmName]="<RESOURCE GROUP>-app-vm"
    fi
    if [[ <PROVISION PUBLIC IP> == False ]]; then
        bastion_public_ip=$(az vm list-ip-addresses -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bastion-vm | jq -r .[0].virtualMachine.network.publicIpAddresses[0].ipAddress)
        outputs[bastionPublicIp]=$bastion_public_ip
    fi
fi

outputs[bigIpInstance01VmId]="${id_1}"
outputs[bigIpInstance02VmId]="${id_2}"

# Run array through function
response=$(verify_outputs "outputs")
spacer=$'\n============\n'

# Evaluate results
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "OUTPUTS PASSED ${spacer}${response}"
fi
