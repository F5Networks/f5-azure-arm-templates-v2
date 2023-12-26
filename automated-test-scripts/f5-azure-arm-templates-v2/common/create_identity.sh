#  expectValue = "Succeeded"
#  scriptTimeout = 15
#  replayEnabled = false
#  replayTimeout = 0


if [[ "<CREATE IDENTITY>" == "False" ]]; then
    # Using a pre-existing identity requires a pre-existing secret
    VAULT_NAME=<RESOURCE GROUP>fv

    SUBSCRIPTION_ID=$(az account show | jq -r .id)

    PRINCIPAL_ID=$(az identity create -g <RESOURCE GROUP> -n <RESOURCE GROUP>id | jq -r .principalId)
    echo "Principal ID: $PRINCIPAL_ID"

    ROLE_ASS=$(az role assignment create --assignee-object-id ${PRINCIPAL_ID} --assignee-principal-type ServicePrincipal --role "Contributor" --scope /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/<RESOURCE GROUP> | jq -r .)
    echo "ROLE_ASS: $ROLE_ASS"

    STORAGE_ROLE_ASS=$(az role assignment create --assignee-object-id ${PRINCIPAL_ID} --assignee-principal-type ServicePrincipal --role "Storage Blob Data Owner" --scope /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/<RESOURCE GROUP> | jq -r .)
    echo "STORAGE_ROLE_ASS: $ROLE_ASS"

    if echo "${ROLE_ASS}" | grep -q "<RESOURCE GROUP>"; then
        echo "Succeeded"
    else
        echo "Failed"
    fi
else
    echo "Not using a pre-existing identity, the template will create one"
    echo "Succeeded"
fi