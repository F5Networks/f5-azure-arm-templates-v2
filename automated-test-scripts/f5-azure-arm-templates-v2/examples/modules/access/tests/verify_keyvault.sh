#!/usr/bin/env bash
#  expectValue = "KeyVault Creation Passed"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10


if [[ "<CREATE SECRET>" == 'false' ]]; then
   echo "KeyVault was not requested"
   echo "KeyVault Creation Passed"
else
   response=$(az keyvault list --resource-group <RESOURCE GROUP> | jq .[].name)
   if [[ $response =~ "<KEY VAULT NAME>" ]]; then
      echo "KeyVault Creation Passed"
   fi
fi