#!/usr/bin/env bash
#  expectValue = "KEYVAULT PASSED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 5

# Script Requires min BASH Version 4
# usage: verify_keyvault associative_array
# Array: [rule]="expected_value"
function verify_keyvault() {
    local -n _arr=$1
    local keyvault_object=$(az keyvault show --name <RESOURCE GROUP>fv --resource-group <RESOURCE GROUP> | jq -r .)
    for r in "${!_arr[@]}";
    do
        local response=$(echo ${keyvault_object} | jq -r .$r)
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
declare -A keyvault
keyvault_id=$(az deployment group show -n <RESOURCE GROUP> -g <RESOURCE GROUP> | jq -r .properties.outputs.keyVaultId.value)
keyvault[id]="${keyvault_id}"
keyvault[properties.accessPolicies\[0\].permissions.secrets\[0\]]="get"
keyvault[properties.provisioningState]="Succeeded"


# Run array through function
response=$(verify_keyvault "keyvault")
spacer=$'\n============\n'

# Evaluate results
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "KEYVAULT PASSED ${spacer}${response}"
fi