#  expectValue = "Template validation succeeded"
#  expectFailValue = "Template validation failed"
#  scriptTimeout = 15
#  replayEnabled = false
#  replayTimeout = 0


TMP_DIR='/tmp/<DEWPOINT JOB ID>'

# download and use --template-file because --template-uri is limiting
TEMPLATE_FILE=${TMP_DIR}/<RESOURCE GROUP>.json
curl -k file://$PWD/examples/modules/access/access.json -o ${TEMPLATE_FILE}

TEMP_VAR="<SOLUTION TYPE>"
if [[ $TEMP_VAR =~ "SOLUTION TYPE" || -z $TEMP_VAR ]]; then
    SOLUTION_TYPE='"solutionType":{"value":"standard"}'
else
    SOLUTION_TYPE='"solutionType":{"value":"<SOLUTION TYPE>"}'
fi

TEMP_VAR="<ROLE NAME>"
if [[ $TEMP_VAR =~ "ROLE NAME" || -z $TEMP_VAR ]]; then
   ROLE_NAME=',"roleName":{"value":"<DEWPOINT JOB ID>-role-name"}'
else
   ROLE_NAME=',"roleName":{"value":"<ROLE NAME>"}'
fi

TEMP_VAR="<ROLE DESCRIPTION>"
if [[ $TEMP_VAR =~ "ROLE DESCRIPTION" || -z $TEMP_VAR ]]; then
   ROLE_DESCRIPTION=',"roleDescription":{"value":"This role is created as part of dewdrop tests"}'
else
   ROLE_DESCRIPTION=',"roleDescription":{"value":"<ROLE DESCRIPTION>"}'
fi

TEMP_VAR="<USER ASSIGNED IDENT NAME>"
if [[ $TEMP_VAR =~ "USER ASSIGNED IDENT NAME" || -z $TEMP_VAR ]]; then
   USER_ASSIGNED_IDENT_NAME=',"userAssignedIdentityName":{"value":""}'
else
   USER_ASSIGNED_IDENT_NAME=',"userAssignedIdentityName":{"value":"<USER ASSIGNED IDENT NAME>"}'
fi

TEMP_VAR="<ROLE PERMISSIONS>"
if [[ $TEMP_VAR =~ "ROLE PERMISSIONS" || -z $TEMP_VAR ]]; then
   CUSTOM_ROLE_PERMISSIONS=',"customRolePermissions":{"value":[]}'
else
   CUSTOM_ROLE_PERMISSIONS=',"customRolePermissions":{"value":<ROLE PERMISSIONS>}'
fi

TEMP_VAR="<ROLE SCOPE>"
if [[ $TEMP_VAR =~ "ROLE SCOPE" || -z $TEMP_VAR ]]; then
   ROLE_SCOPE=',"customAssignableScopes":{"value":[]}'
else
   ROLE_SCOPE=',"customAssignableScopes":{"value":["<ROLE SCOPE>"]}'
fi

SECRET_ID=$(az keyvault secret show --vault-name <RESOURCE GROUP>fv -n <RESOURCE GROUP>bigiq | jq .id --raw-output)
SECRET_ID_STRING=',"secretId":{"value":"'"$SECRET_ID"'"}'

DEPLOY_PARAMS='{"$schema":"http:\/\/schema.management.azure.com\/schemas\/2015-01-01\/deploymentParameters.json#","contentVersion":"1.0.0.0","parameters":{'${SOLUTION_TYPE}${ROLE_NAME}${ROLE_DESCRIPTION}${CUSTOM_ROLE_PERMISSIONS}${SECRET_ID_STRING}${USER_ASSIGNED_IDENT_NAME}${ROLE_SCOPE}'}}'

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