#  expectValue = "Succeeded"
#  scriptTimeout = 3
#  replayEnabled = false
#  replayTimeout = 0

cmd="<CMD>"

az vmss update -g <RESOURCE GROUP> --name <RESOURCE GROUP>-vmss --set virtualMachineProfile.extensionProfile.extensions[0].settings.commandToExecute="${cmd}" --no-wait

echo "Succeeded"