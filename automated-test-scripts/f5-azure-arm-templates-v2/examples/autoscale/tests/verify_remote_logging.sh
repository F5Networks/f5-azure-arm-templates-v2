#  expectValue = "Succeeded"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 30

RESPONSE=$(az monitor log-analytics workspace table list --resource-group <RESOURCE GROUP> --workspace-name <RESOURCE GROUP>-log-wrkspc | jq '.[] | select(.name=="F5Telemetry_ASM_CL")')

if echo $RESPONSE | grep -q "Microsoft.OperationalInsights"; then
    echo "Succeeded"
else
    echo "Failed"
fi
