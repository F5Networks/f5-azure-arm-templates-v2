#  expectValue = "Succeeded"
#  scriptTimeout = 5
#  replayEnabled = true
#  replayTimeout = 60


if [[ "<CREATE IDENTITY>" == "False" ]]; then
    # Using a pre-existing identity requires a pre-existing secret
    VAULT_NAME=<RESOURCE GROUP>fv

    PRINCIPAL_ID=$(az identity show -g <RESOURCE GROUP> -n <RESOURCE GROUP>id | jq -r .principalId)
    echo "Principal ID: $PRINCIPAL_ID"

    VAULT_ASS=$(az keyvault set-policy --name ${VAULT_NAME} --secret-permissions get list --object-id ${PRINCIPAL_ID} | jq -r .)
    echo "VAULT_ASS: $VAULT_ASS"

    if echo "${VAULT_ASS}" | grep -q "<RESOURCE GROUP>"; then
        echo "Succeeded"
    else
        echo "Failed"
    fi
else
    echo "Not using a pre-existing identity, the template will create one"
    echo "Succeeded"
fi