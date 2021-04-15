#  expectValue = "Succeeded"
#  expectFailValue = "Failed"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 30

SCALE_DOWN=$(az monitor autoscale update -g <RESOURCE GROUP> -n <RESOURCE GROUP>-autoscaleconfig --min-count 1 --max-count 1 --count 1 | jq .name)
echo "SCALE_DOWN: ${SCALE_DOWN}"

if [[ $SCALE_DOWN == \"<RESOURCE GROUP>-autoscaleconfig\" ]]; then
    echo "Succeeded"
else
    echo "Failed"
fi
