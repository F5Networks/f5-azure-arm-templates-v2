#!/usr/bin/env bash
#  expectValue = "APP INSIGHTS PASSED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 5

# Script Requires min BASH Version 4
# Install the app insights cli extension (preview)
az extension add --name application-insights

# usage: verify_app_insights_resource associative_array
# Array: [rule]="expected_value"
function verify_app_insights_resource() {
    local -n _arr=$1
    local app_insights_object=$(az monitor app-insights component show --resource-group <RESOURCE GROUP> | jq -r . | tr '[:upper:]' '[:lower:]')
    for r in "${!_arr[@]}";
    do
        local response=$(echo ${app_insights_object} | jq -r .$r)
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
# lowercasing everything because Azure is inconsistent
declare -A app_insights
app_insights_id=$(az deployment group show -n <RESOURCE GROUP> -g <RESOURCE GROUP> | jq -r .properties.outputs.applicationInsightsId.value | tr '[:upper:]' '[:lower:]')
app_insights[\[\].id]="${app_insights_id}"
app_insights[\[\].applicationid]="<RESOURCE GROUP>-function"
app_insights[\[\].provisioningstate]="succeeded"


# Run array through function
response=$(verify_app_insights_resource "app_insights")
spacer=$'\n============\n'

# Evaluate results
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "APP INSIGHTS PASSED ${spacer}${response}"
fi