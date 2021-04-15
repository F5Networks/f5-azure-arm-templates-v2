#!/usr/bin/env bash
#  expectValue = "Custom Role Def Creation Passed"
#  scriptTimeout = 10
#  replayEnabled = true
#  replayTimeout = 30


TEMP_VAR="<CUSTOM ROLE NAME>"
if [[ $TEMP_VAR =~ "CUSTOM ROLE NAME" || -z $TEMP_VAR ]]; then
    echo "Custom Role Definition was not requested"
    echo "Custom Role Def Creation Passed"
else
    response=$(az role definition list -g <RESOURCE GROUP> | jq '.[] | select(.roleName=="<CUSTOM ROLE NAME>")')
    roleName=$(echo $response | jq .roleName)
    roleDescription=$(echo $response | jq .description)
    if [[ $roleName =~ "<CUSTOM ROLE NAME>" &&  $roleDescription =~ "<CUSTOM ROLE DESCRIPTION>" ]]; then
        echo "Custom Role Def Creation Passed"
    fi
fi