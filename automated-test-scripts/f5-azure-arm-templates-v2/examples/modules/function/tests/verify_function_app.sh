#!/usr/bin/env bash
#  expectValue = "FUNCTION APP PASSED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 5

# Script Requires min BASH Version 4
# usage: verify_function_app_resource associative_array
# Array: [rule]="expected_value"
function verify_function_app_resource() {
    local -n _arr=$1
    local function_app_object=$(az functionapp config show --name <RESOURCE GROUP>-function --resource-group <RESOURCE GROUP> | jq -r .)
    for r in "${!_arr[@]}";
    do
        local response=$(echo ${function_app_object} | jq -r .$r)
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
declare -A function_app
function_app_id=$(az deployment group show -n <RESOURCE GROUP> -g <RESOURCE GROUP> | jq -r .properties.outputs.functionAppId.value)
function_app[id]="${function_app_id}"
function_app[linuxFxVersion]="PYTHON|3.7"
function_app[vnetName]="<RESOURCE GROUP>-vnet"


# Run array through function
response=$(verify_function_app_resource "function_app")
spacer=$'\n============\n'

# Evaluate results
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "FUNCTION APP PASSED ${spacer}${response}"
fi