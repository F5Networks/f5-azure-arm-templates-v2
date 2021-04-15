#  expectValue = "SUCCEEDED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10

# get app address
# the first (primary) IP config is always assigned to the self IP, so we need the second IP config
if [[ <NIC COUNT> -eq 1 ]]; then
    APP_ADDRESS=$(az vm list-ip-addresses -g <RESOURCE GROUP> -n <RESOURCE GROUP>-vm | jq -r .[0].virtualMachine.network.publicIpAddresses[1].ipAddress)
else
    APP_ADDRESS=$(az vm list-ip-addresses -g <RESOURCE GROUP> -n <RESOURCE GROUP>-vm | jq -r .[1].virtualMachine.network.publicIpAddresses[1].ipAddress)
fi
echo "APP_ADDRESS: ${APP_ADDRESS}"

# confirm app is available
ACCEPTED_RESPONSE=$(curl -vv http://${APP_ADDRESS})
echo "ACCEPTED_RESPONSE: ${ACCEPTED_RESPONSE}"

# try something illegal (enforcement mode should be set to blocking by default)
REJECTED_RESPONSE=$(curl -vv -X DELETE http://${APP_ADDRESS})
echo "REJECTED_RESPONSE: ${REJECTED_RESPONSE}"

if echo $ACCEPTED_RESPONSE | grep -q "Demo App" && echo $REJECTED_RESPONSE | grep -q "The requested URL was rejected"; then
    echo "SUCCEEDED"
else
    echo "FAILED"
fi