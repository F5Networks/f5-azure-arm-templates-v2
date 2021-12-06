#!/usr/bin/env bash
#  expectValue = "FUNCTION APP SETTINGS PASSED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 5

# Script Requires min BASH Version 4
# usage: verify_function_app_settings associative_array
# Array: [rule]="expected_value"
function verify_function_app_settings() {
    local -n _arr=$1
    local function_app_settings_object=$(az functionapp config appsettings list --name <RESOURCE GROUP>-function -g <RESOURCE GROUP> | jq -r 'map( { (.name): .value } ) | add')
    for r in "${!_arr[@]}";
    do
        local response=$(echo ${function_app_settings_object} | jq -r .$r)
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

USER_ASSIGNED_ID=$(az identity show --name <USER ASSIGNED IDENT NAME> --resource-group <RESOURCE GROUP> | jq -r .clientId)

# Build associative array
# array_name[jq_filter]=expected_response
declare -A function_app_settings
function_app_settings[AZURE_CLIENT_ID]="${USER_ASSIGNED_ID}"
function_app_settings[AZURE_RESOURCE_GROUP]="<RESOURCE GROUP>"
function_app_settings[AZURE_VMSS_NAME]="<RESOURCE GROUP>"
function_app_settings[FUNCTIONS_WORKER_RUNTIME]="python"
function_app_settings[RUNTIME_INIT_CONFIG]="<BIGIP RUNTIME INIT CONFIG>"
function_app_settings[WEBSITE_ENABLE_SYNC_UPDATE_SITE]="True"

# Run array through function
response=$(verify_function_app_settings "function_app_settings")
spacer=$'\n============\n'

# Evaluate results
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "FUNCTION APP SETTINGS PASSED ${spacer}${response}"
fi