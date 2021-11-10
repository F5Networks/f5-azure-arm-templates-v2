#  expectValue = "Succeeded"
#  scriptTimeout = 15
#  replayEnabled = false
#  replayTimeout = 0

az keyvault create --location <REGION> \
	--name <RESOURCE GROUP>fv \
	--resource-group <RESOURCE GROUP> \
	--bypass AzureServices \
	--default-action Allow \
	--sku standard \
	--tags creator=dewdrop delete=True

az keyvault secret set --name <RESOURCE GROUP>bigiq \
	--vault-name  <RESOURCE GROUP>fv \
	--value <SECRET VALUE>