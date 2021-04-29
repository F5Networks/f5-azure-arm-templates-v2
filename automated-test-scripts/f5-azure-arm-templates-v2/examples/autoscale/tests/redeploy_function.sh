#  expectValue = "Succeeded"
#  scriptTimeout = 180
#  replayEnabled = false
#  replayTimeout = 0

TMP_DIR='/tmp/<DEWPOINT JOB ID>'

curl -vv http://cdn.f5.com/product/cloudsolutions/f5-cloud-functions/azure/TimerTriggerRevoke/develop/timer_trigger_revoke.zip -o ${TMP_DIR}/timer_trigger_revoke.zip

az functionapp config appsettings delete -g <RESOURCE GROUP> --name <RESOURCE GROUP>fn-function --setting-names WEBSITE_RUN_FROM_PACKAGE

az functionapp config appsettings set -g <RESOURCE GROUP> --name <RESOURCE GROUP>fn-function --settings "F5_DISABLE_SSL_WARNINGS=true"

REDEPLOYED=$(az functionapp deployment source config-zip -g <RESOURCE GROUP> --name <RESOURCE GROUP>fn-function --src ${TMP_DIR}/timer_trigger_revoke.zip --build-remote true | jq -r .message)

echo "Redeployment status: ${REDEPLOYED}"

if [[ ${REDEPLOYED} =~ "Created" ]]; then
    echo "Succeeded"
else
    echo "Failed"
fi