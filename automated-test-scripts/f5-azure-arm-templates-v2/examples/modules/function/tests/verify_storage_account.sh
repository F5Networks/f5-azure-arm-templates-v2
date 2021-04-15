#!/usr/bin/env bash
#  expectValue = "STORAGE ACCOUNT PASSED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 5

# Script Requires min BASH Version 4
# usage: verify_storage_account_resource associative_array
# Array: [rule]="expected_value"
function verify_storage_account_resource() {
    local -n _arr=$1
    local storage_account_object=$(az storage account list --resource-group <RESOURCE GROUP> | jq -r .)
    for r in "${!_arr[@]}";
    do
        local response=$(echo ${storage_account_object} | jq -r .$r)
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
declare -A storage_account
storage_account_id=$(az deployment group show -n <RESOURCE GROUP> -g <RESOURCE GROUP> | jq -r .properties.outputs.storageAccountId.value)
storage_account[\[\].id]="${storage_account_id}"
storage_account[\[\].provisioningState]="Succeeded"


# Run array through function
response=$(verify_storage_account_resource "storage_account")
spacer=$'\n============\n'

# Evaluate results
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "STORAGE ACCOUNT PASSED ${spacer}${response}"
fi