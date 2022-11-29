#  expectValue = "Succeeded"
#  scriptTimeout = 15
#  replayEnabled = false
#  replayTimeout = 0


if [[ "<CREATE IDENTITY>" == "False" ]]; then
    # In this case, the template will create the identity
    # Using a pre-existing identity requires a pre-existing secret
    VAULT_NAME=<RESOURCE GROUP>fv

    PRINCIPAL_ID=$(az identity create -g <RESOURCE GROUP> -n <RESOURCE GROUP>id | jq -r .principalId)
    echo "Principal ID: $PRINCIPAL_ID"

    ROLE_ASS=$(az role assignment create --assignee-object-id ${PRINCIPAL_ID} --assignee-principal-type ServicePrincipal --role "Contributor" --resource-group <RESOURCE GROUP> | jq -r .resourceGroup)
    echo "ROLE_ASS: $ROLE_ASS"

    VAULT_ASS=$(az keyvault set-policy --name ${VAULT_NAME} --secret-permissions get list --object-id ${PRINCIPAL_ID} | jq -r .)
    echo "VAULT_ASS: $VAULT_ASS"

    if [[ $VAULT_ASS == "<RESOURCE GROUP>" ]]; then
        echo "Succeeded"
    else
        echo "Failed"
    fi
else
    echo "Not using a pre-existing identity, the template will create one"
    echo "Succeeded"
fi