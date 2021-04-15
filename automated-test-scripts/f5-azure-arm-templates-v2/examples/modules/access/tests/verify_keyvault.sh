#!/usr/bin/env bash
#  expectValue = "KeyVault Creation Passed"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10


TEMP_VAR="<KEY VAULT NAME>"
if [[ $TEMP_VAR =~ "KEY VAULT NAME" || -z $TEMP_VAR ]]; then
   echo "KeyVault was not requested"
   echo "KeyVault Creation Passed"
else
   response=$(az keyvault list --resource-group <RESOURCE GROUP> | jq .[].name)
   if [[ $response =~ "<KEY VAULT NAME>" ]]; then
      echo "KeyVault Creation Passed"
   fi
fi