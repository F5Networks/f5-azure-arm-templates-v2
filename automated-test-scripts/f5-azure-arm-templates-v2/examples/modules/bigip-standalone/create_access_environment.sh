#  expectValue = "Template validation succeeded"
#  expectFailValue = "Template validation failed"
#  scriptTimeout = 15
#  replayEnabled = false
#  replayTimeout = 0


TMP_DIR='/tmp/<DEWPOINT JOB ID>'

# download and use --template-file because --template-uri is limiting
TEMPLATE_FILE=${TMP_DIR}/<RESOURCE GROUP>.json
curl -k file://$PWD/examples/modules/access/access.json -o ${TEMPLATE_FILE}

TEMP_VAR="<BUILT IN ROLE TYPE>"
if [[ $TEMP_VAR =~ "BUILT IN ROLE TYPE" || -z $TEMP_VAR ]]; then
    BUILT_INT_ROLE_TYPE='"builtInRoleType":{"value":"Reader"}'
else
    BUILT_INT_ROLE_TYPE='"builtInRoleType":{"value":"<BUILT IN ROLE TYPE>"}'
fi

TEMP_VAR="<CUSTOM ROLE NAME>"
if [[ $TEMP_VAR =~ "CUSTOM ROLE NAME" || -z $TEMP_VAR ]]; then
   CUSTOM_ROLE_NAME=',"customRoleName":{"value":""}'
else
   CUSTOM_ROLE_NAME=',"customRoleName":{"value":"<CUSTOM ROLE NAME>"}'
fi

TEMP_VAR="<CUSTOM ROLE DESCRIPTION>"
if [[ $TEMP_VAR =~ "CUSTOM ROLE DESCRIPTION" || -z $TEMP_VAR ]]; then
   CUSTOM_ROLE_DESCRIPTION=',"customRoleDescription":{"value":""}'
else
   CUSTOM_ROLE_DESCRIPTION=',"customRoleDescription":{"value":"<CUSTOM ROLE DESCRIPTION>"}'
fi

TEMP_VAR="<CUSTOM ROLE PERMISSIONS>"
if [[ $TEMP_VAR =~ "CUSTOM ROLE PERMISSIONS" || -z $TEMP_VAR ]]; then
   CUSTOM_ROLE_PERMISSIONS=',"customRolePermissions":{"value":[]}'
else
   CUSTOM_ROLE_PERMISSIONS=',"customRolePermissions":{"value":<CUSTOM ROLE PERMISSIONS>}'
fi

TEMP_VAR="<KEY VAULT NAME>"
if [[ $TEMP_VAR =~ "KEY VAULT NAME" || -z $TEMP_VAR ]]; then
   KEY_VAULT_NAME=',"keyVaultName":{"value":""}'
else
   KEY_VAULT_NAME=',"keyVaultName":{"value":"<KEY VAULT NAME>"}'
fi

TEMP_VAR="<USER ASSIGNED IDENT NAME>"
if [[ $TEMP_VAR =~ "USER ASSIGNED IDENT NAME" || -z $TEMP_VAR ]]; then
   USER_ASSIGNED_IDENT_NAME=',"userAssignedIdentityName":{"value":""}'
else
   USER_ASSIGNED_IDENT_NAME=',"userAssignedIdentityName":{"value":"<USER ASSIGNED IDENT NAME>"}'
fi

TEMP_VAR="<SECRET NAME>"
if [[ $TEMP_VAR =~ "SECRET NAME" || -z $TEMP_VAR ]]; then
   SECERT_NAME=',"secretName":{"value":""}'
else
   SECERT_NAME=',"secretName":{"value":"<SECRET NAME>"}'
fi

TEMP_VAR="<SECRET VALUE>"
if [[ $TEMP_VAR =~ "SECRET VALUE" || -z $TEMP_VAR ]]; then
   SECERT_VALUE=',"secretValue":{"value":""}'
else
   SECERT_VALUE=',"secretValue":{"value":"<SECRET VALUE>"}'
fi

TEMP_VAR="<CUSTOM ROLE SCOPE>"
if [[ $TEMP_VAR =~ "CUSTOM ROLE SCOPE" || -z $TEMP_VAR ]]; then
   CUSTOM_ROLE_SCOPE=',"customRoleAssignableScopes":{"value":[]}'
else
   CUSTOM_ROLE_SCOPE=',"customRoleAssignableScopes":{"value":["<CUSTOM ROLE SCOPE>"]}'
fi

DEPLOY_PARAMS='{"$schema":"http:\/\/schema.management.azure.com\/schemas\/2015-01-01\/deploymentParameters.json#","contentVersion":"1.0.0.0","parameters":{'${BUILT_INT_ROLE_TYPE}${CUSTOM_ROLE_NAME}${CUSTOM_ROLE_DESCRIPTION}${CUSTOM_ROLE_PERMISSIONS}${KEY_VAULT_NAME}${USER_ASSIGNED_IDENT_NAME}${SECERT_NAME}${SECERT_VALUE}${CUSTOM_ROLE_SCOPE}'}}'

DEPLOY_PARAMS_FILE=${TMP_DIR}/deploy_params.json

# save deployment parameters to a file, to avoid weird parameter parsing errors with certain values
# when passing as a variable. I.E. when providing an sshPublicKey
echo ${DEPLOY_PARAMS} > ${DEPLOY_PARAMS_FILE}

echo "DEBUG: DEPLOY PARAMS"
echo ${DEPLOY_PARAMS}

VALIDATE_RESPONSE=$(az deployment group validate --resource-group <RESOURCE GROUP> --template-file ${TEMPLATE_FILE} --parameters @${DEPLOY_PARAMS_FILE})
VALIDATION=$(echo ${VALIDATE_RESPONSE} | jq .properties.provisioningState)
if [[ $VALIDATION == \"Succeeded\" ]]; then
    az deployment group create --verbose --no-wait --template-file ${TEMPLATE_FILE} -g <RESOURCE GROUP> -n <RESOURCE GROUP>-access-env --parameters @${DEPLOY_PARAMS_FILE}
    echo "Template validation succeeded"
else
    echo "Template validation failed: ${VALIDATE_RESPONSE}"
fi