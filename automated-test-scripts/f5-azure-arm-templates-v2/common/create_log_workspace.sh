#  expectValue = "Succeeded"
#  scriptTimeout = 15
#  replayEnabled = false
#  replayTimeout = 0

TMP_DIR='/tmp/<DEWPOINT JOB ID>'
curl -k https://f5-cft.s3.amazonaws.com/QA/azure_v2_autoscale_log_workspace.json -o ${TMP_DIR}/workspace.json

if [[ ! <CREATE WORKSPACE> == True ]]; then
    az deployment group create --resource-group <RESOURCE GROUP> --name <RESOURCE GROUP>-log-wrkspc --template-file ${TMP_DIR}/workspace.json --parameters {\"workspaceName\":{\"value\":\"<RESOURCE GROUP>-log-wrkspc\"}}
else
    echo "Succeeded"
fi

