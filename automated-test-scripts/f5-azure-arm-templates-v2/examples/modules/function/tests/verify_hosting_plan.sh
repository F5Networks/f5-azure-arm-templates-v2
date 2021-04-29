#!/usr/bin/env bash
#  expectValue = "HOSTING PLAN PASSED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 5

# Script Requires min BASH Version 4
# usage: verify_hosting_plan_resource associative_array
# Array: [rule]="expected_value"
function verify_hosting_plan_resource() {
    local -n _arr=$1
    local hosting_plan_object=$(az appservice plan show --name <RESOURCE GROUP>-plan --resource-group <RESOURCE GROUP> | jq -r .)
    for r in "${!_arr[@]}";
    do
        local response=$(echo ${hosting_plan_object} | jq -r .$r)
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
declare -A hosting_plan
plan_id=$(az deployment group show -n <RESOURCE GROUP> -g <RESOURCE GROUP> | jq -r .properties.outputs.hostingPlanId.value)
hosting_plan[id]="${plan_id}"
hosting_plan[provisioningState]="Succeeded"
hosting_plan[reserved]="true"
hosting_plan[status]="Ready"


# Run array through function
response=$(verify_hosting_plan_resource "hosting_plan")
spacer=$'\n============\n'

# Evaluate results
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "HOSTING PLAN PASSED ${spacer}${response}"
fi