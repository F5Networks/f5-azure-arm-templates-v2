#!/usr/bin/env bash
#  expectValue = "ROLE ASSIGNMENT PASSED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 5

# Script Requires min BASH Version 4
# usage: verify_role_assignment_resource associative_array
# Array: [rule]="expected_value"
function verify_role_assignment_resource() {
    local -n _arr=$1
    local role_assignment_object=$(az role assignment list --resource-group <RESOURCE GROUP> | jq -r .)
    for r in "${!_arr[@]}";
    do
        local response=$(echo ${role_assignment_object} | jq -r .$r)
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
declare -A role_assignment
role_assignment_id=$(az deployment group show -n <RESOURCE GROUP> -g <RESOURCE GROUP> | jq -r .properties.outputs.roleAssignmentId.value)
resource_group_id=$(az group show -n <RESOURCE GROUP> | jq -r .id)
role_assignment[\[\].resourceGroup]="<RESOURCE GROUP>"
role_assignment[\[\].roleDefinitionName]="Contributor"
role_assignment[\[\].scope]="<RESOURCE GROUP>"
role_assignment[\[\].id]="${role_assignment_id}"


# Run array through function
response=$(verify_role_assignment_resource "role_assignment")
spacer=$'\n============\n'

# Evaluate results
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "ROLE ASSIGNMENT PASSED ${spacer}${response}"
fi