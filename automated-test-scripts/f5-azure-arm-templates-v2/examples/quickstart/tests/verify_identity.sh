#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10


if [[ "<CREATE SECRET>" == "True" ]]; then
    IDENTITY_RESPONSE=$(az vm identity show --name <RESOURCE GROUP>-bigip-vm-01 --resource-group <RESOURCE GROUP> | jq .userAssignedIdentities)
    if echo ${IDENTITY_RESPONSE} | grep -q "<RESOURCE GROUP>-bigip-user-identity"; then
        echo "SUCCESS"
    fi
else
    echo "Not creating an identity"
    echo "SUCCESS"
fi