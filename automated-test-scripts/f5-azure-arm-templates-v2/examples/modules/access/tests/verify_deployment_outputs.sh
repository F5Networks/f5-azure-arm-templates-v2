#!/usr/bin/env bash
#  expectValue = "DEPLOYMENT OUTPUTS VALIDATED"
#  expectFailValue = "OUTPUTS ERROR"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10

deploymentOutputs=$(az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP> | jq '.properties.outputs')

TEMP_VAR="<ROLE NAME>"
if [[ $TEMP_VAR =~ "ROLE NAME" || -z $TEMP_VAR ]]; then
    echo "Custom Role Definition creation was not requested"
else
    if [[ -z $(echo $deploymentOutputs | jq .roleDefinitionId) ]]; then
        echo "OUTPUTS ERROR - CUSTOM DEF ROLE";
    fi
fi

TEMP_VAR="<USER ASSIGNED IDENT NAME>"
if [[ $TEMP_VAR =~ "USER ASSIGNED IDENT NAME" || -z $TEMP_VAR ]]; then
   echo "User Identity creation was not requested"
else
   if [[ -z $(echo $deploymentOutputs | jq .userAssignedIdentityName) ]]; then
      echo "OUTPUTS ERROR - IDENTITY NAME"
   fi
fi

if [[ "<CREATE SECRET>" == 'true' || "<USE SECRET>" == 'true' ]]; then
   if [[ -z $(echo $deploymentOutputs | jq .keyVaultName) ]]; then
      echo "OUTPUTS ERROR - KEY VAULT NAME"
   fi
   if [[ -z $(echo $deploymentOutputs | jq .secretId) ]]; then
      echo "OUTPUTS ERROR - SECRET ID"
   fi
else
   echo "KeyVault was not requested"
fi

echo "DEPLOYMENT OUTPUTS VALIDATED"