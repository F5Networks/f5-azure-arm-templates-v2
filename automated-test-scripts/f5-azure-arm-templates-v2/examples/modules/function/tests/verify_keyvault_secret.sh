#!/usr/bin/env bash
#  expectValue = "KEYVAULT SECRET PASSED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 5

# Script Requires min BASH Version 4
# usage: verify_keyvault_secret associative_array
# Array: [rule]="expected_value"
function verify_keyvault_secret() {
    local -n _arr=$1
     # We need to grant ourselves read access to the secret
    az keyvault set-policy --name <RESOURCE GROUP>fv --spn d40aad56-b0bd-466d-a6c4-6c9c4d0f9aa7 --secret-permissions list get
    local keyvault_secret_object=$(az keyvault secret show --vault-name <RESOURCE GROUP>fv -n <RESOURCE GROUP>bigiq | jq -r .)
    for r in "${!_arr[@]}";
    do
        local response=$(echo ${keyvault_secret_object} | jq -r .$r)
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
declare -A keyvault_secret
keyvault_secret[value]="<SECRET VALUE>"

# Run array through function
response=$(verify_keyvault_secret "keyvault_secret")
spacer=$'\n============\n'

# Evaluate results
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "KEYVAULT SECRET PASSED ${spacer}${response}"
fi