#  expectValue = "Succeeded"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 30

if [[ <CREATE WORKSPACE> == false ]]; then
    RESPONSE=$(az monitor log-analytics workspace table list --resource-group <RESOURCE GROUP> --workspace-name <RESOURCE GROUP>-log-wrkspc | jq '.[] | select(.name=="F5Telemetry_ASM_CL")')
else
    RESPONSE=$(az monitor log-analytics workspace table list --resource-group <RESOURCE GROUP> --workspace-name f5telemetry | jq '.[] | select(.name=="F5Telemetry_ASM_CL")')
fi


if echo $RESPONSE | grep -q "Microsoft.OperationalInsights"; then
    echo "Succeeded"
else
    echo "Failed"
fi
