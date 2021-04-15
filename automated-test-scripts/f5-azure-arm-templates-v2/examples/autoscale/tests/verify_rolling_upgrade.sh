#  expectValue = "Succeeded"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 180

RESPONSE=$(az vmss rolling-upgrade get-latest -g <RESOURCE GROUP> --name <RESOURCE GROUP>-vmss | jq -r .runningStatus.code)

echo "Upgrade status: ${RESPONSE}"

if echo $RESPONSE | grep -q "Completed"; then
    echo "Succeeded"
else
    echo "Failed"
fi