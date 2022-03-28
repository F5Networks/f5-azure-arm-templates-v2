#  expectValue = "Succeeded"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 60


if [[ "<PROVISION EXTERNAL LB>" == "False" ]]; then
    echo "Succeeded"
else
    # get app address
    APP_ADDRESS=$(az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP> | jq -r '.properties.outputs["wafPublicIps"].value[0]')
    echo "APP_ADDRESS: ${APP_ADDRESS}"

    # confirm app is available
    ACCEPTED_RESPONSE=$(curl -vv http://${APP_ADDRESS})
    echo "ACCEPTED_RESPONSE: ${ACCEPTED_RESPONSE}"

    if echo $ACCEPTED_RESPONSE | grep -q "Demo App"; then
        echo "Succeeded"
    else
        echo "Failed"
    fi
fi