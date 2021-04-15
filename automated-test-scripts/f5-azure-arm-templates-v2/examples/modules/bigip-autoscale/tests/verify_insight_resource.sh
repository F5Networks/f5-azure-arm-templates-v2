#!/usr/bin/env bash
#  expectValue = "INSIGHT COMPONENT CREATION PASSED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 5

# Script Requires min BASH Version 4
# usage: verify_insight_resource associative_array
# Array: [rule]="expected_value"
function verify_insight_resource() {
    local -n _arr=$1
    local insight_object=$(az monitor app-insights component show --resource-group <RESOURCE GROUP> --app <APP INSIGHTS> | jq -r .)
    for r in "${!_arr[@]}";
    do
        local response=$(echo ${insight_object} | jq -r .$r)
        if echo "$response" | grep -q "${_arr[$r]}"; then
            rule_result="Rule:${r}      Response:$response     Value:${_arr[$r]}:PASSED"
        else
            rule_result="Rule:${r}      Response:$response     Value:${_arr[$r]}:FAILED"
        fi
        spacer=$'\n============\n'
        local results="${results}${rule_result}${spacer}"
    done
    echo "$results"
}

# Build associative security group arrays
# array_name[jq_filter]=expected_response
declare -A insight_compnents

if [[ "<APP INSIGHTS>" == "" ]]; then
    echo "Microsoft.Insight compnent not being created, INSIGHT COMPONENT CREATION PASSED"
else
    id=$(az deployment group show -n <RESOURCE GROUP> -g <RESOURCE GROUP> | jq -r .properties.outputs.appInsightsComponentID.value)
    insight_compnents[resourceGroup]="<RESOURCE GROUP>"
    insight_compnents[id]="${id}"
fi


# Run array's through function
response=$(verify_insight_resource "insight_compnents")
spacer=$'\n============\n'

# Evaluate results
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "INSIGHT COMPONENT CREATION PASSED ${spacer}${response}"
fi