#  expectValue = "good"
#  scriptTimeout = 2
#  replayEnabled = false
#  replayTimeout = 20

TMP_DIR='/tmp/<DEWPOINT JOB ID>'

echo "--- Github Status ---"
github_response=`curl https://status.github.com/api/status.json?callback-apiStatus | jq .status --raw-output`

# get the private key from key vault via file
SSH_PORT='22'
IP1=$(az vmss list-instance-public-ips -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bigip-vmss | jq -r .[0].ipAddress)
IP2=$(az vmss list-instance-public-ips -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bigip-vmss | jq -r .[1].ipAddress)

echo "Verify IP1=$IP1"
echo "Verify IP2=$IP2"

# get deployment status
echo "--- Deployment Status ---"
STATUS=$(az deployment operation group list -g <RESOURCE GROUP> -n <RESOURCE GROUP>)
echo $STATUS | jq .

# build logs list
CUST_SCRIPT_LOC="/var/lib/waagent/custom-script/download/<SEQUENCE NUMBER>"
# Expected logs
LOGS="$CUST_SCRIPT_LOC/stdout $CUST_SCRIPT_LOC/stderr /var/log/waagent.log /var/log/restnoded/restnoded.log /var/log/cloud/azure/install.log /var/log/cloud/bigIpRuntimeInit.log"

if [[ -n "$IP1" ]]; then
  for LOG in $LOGS; do
    echo "------------------------LOG:$LOG ------------------------"
    filename=$(basename ${LOG})
    echo $filename
    sshpass -p '<SECRET VALUE>' scp -o "StrictHostKeyChecking no" -P $SSH_PORT admin@${IP1}:${base}${LOG} ${TMP_DIR}/${filename}-<REGION>
    cat ${TMP_DIR}/${filename}-<REGION> 2>/dev/null
    echo
  done
  ssh-keygen -R $IP 2>/dev/null
else
  echo "Nothing matched, logs not being collected"
fi

if [[ -n "$IP2" ]]; then
  for LOG in $LOGS; do
    echo "------------------------LOG:$LOG ------------------------"
    filename=$(basename ${LOG})
    echo $filename
    sshpass -p '<SECRET VALUE>' scp -o "StrictHostKeyChecking no" -P $SSH_PORT admin@${IP2}:${base}${LOG} ${TMP_DIR}/${filename}-<REGION>
    cat ${TMP_DIR}/${filename}-<REGION> 2>/dev/null
    echo
  done
  ssh-keygen -R $IP2 2>/dev/null
else
  echo "Second Big-IP Not Present"
fi

if [[ $github_response == "good" ]]; then
    echo "GitHub status is good"
fi