#!/usr/bin/env bash
#  expectValue = "Identity Creation Passed"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 20


TEMP_VAR="<USER ASSIGNED IDENT NAME>"
if [[ $TEMP_VAR =~ "USER ASSIGNED IDENT NAME" || -z $TEMP_VAR ]]; then
   echo "Identity was not requested"
   echo "Identity Creation Passed"
else
   response=$(az identity list --resource-group <RESOURCE GROUP> | jq .[].name)
   if [[ $response =~ "<USER ASSIGNED IDENT NAME>" ]]; then
      echo "Identity Creation Passed"
   fi
fi
