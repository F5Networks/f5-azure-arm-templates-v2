#!/usr/bin/env bash
#  expectValue = "DEPLOYMENT OUTPUTS VALIDATED"
#  expectFailValue = "OUTPUTS ERROR"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10

deploymentOutputs=$(az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP> | jq '.properties.outputs')

if [[ -z $(echo $deploymentOutputs | jq .builtInRoleId) ]]; then
    echo "OUTPUTS ERROR - BUILTIN ROLE ID";
fi

TEMP_VAR="<CUSTOM ROLE NAME>"
if [[ $TEMP_VAR =~ "CUSTOM ROLE NAME" || -z $TEMP_VAR ]]; then
    echo "Custom Role Definition creation was not requested"
else
    if [[ -z $(echo $deploymentOutputs | jq .customRoleDefinitionId) ]]; then
        echo "OUTPUTS ERROR - CUSTOM DEF ROLE";
    fi
fi

TEMP_VAR="<KEY VAULT NAME>"
if [[ $TEMP_VAR =~ "KEY VAULT NAME" || -z $TEMP_VAR ]]; then
   echo "KeyVault creation was not requested"
else
   if [[ -z $(echo $deploymentOutputs | jq .keyVaultName) ]]; then
      echo "OUTPUTS ERROR - KEY VAULT"
   fi
fi

TEMP_VAR="<SECRET NAME>"
if [[ $TEMP_VAR =~ "SECRET NAME" || -z $TEMP_VAR ]]; then
   echo "Secret creation was not requested"
else
   if [[ -z $(echo $deploymentOutputs | jq .secretName) ]]; then
      echo "OUTPUTS ERROR - SECRET NAME"
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

echo "DEPLOYMENT OUTPUTS VALIDATED"