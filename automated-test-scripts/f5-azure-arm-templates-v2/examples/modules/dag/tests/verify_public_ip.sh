#!/usr/bin/env bash
#  expectValue = "PUBLIC IP CREATION PASSED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10


function verify_public_ip() {
    local -n _arr=$1
    for r in "${!_arr[@]}";
    do
        local response=$(az network public-ip show --resource-group <RESOURCE GROUP> -n dd-dag-<DEWPOINT JOB ID>-$r | jq -r .id)
        if echo "$response" | grep -q "${_arr[$r]}"; then
            public_ip_result="IP:${r},Value:${_arr[$r]},PASSED"
        else
            public_ip_result="IP:${r},Value:${_arr[$r]},FAILED"
        fi
        spacer=$'\n============\n'
        local results="${results}${public_ip_result}${spacer}"
    done
    echo "$results"
}

# setup management public ip array
if [ <NUMBER PUBLIC MGMT IP ADDRESSES> -gt 0 ]; then
    declare -A mgmtip
    upperlimit=$((<NUMBER PUBLIC MGMT IP ADDRESSES>))
    for ((s=1; s<=upperlimit; s++));
        do         
            mgmtip[mgmt-pip-0${s}]="dd-dag-<DEWPOINT JOB ID>-mgmt-pip-0${s}"
        done
fi

# setup application Public ip array
if [ <NUMBER PUBLIC EXT IP ADDRESSES> -gt 0 ]; then
    declare -A appip
    upperlimit=$((<NUMBER PUBLIC EXT IP ADDRESSES>))
    for ((s=1; s<=upperlimit; s++));
        do         
            appip[app-pip-0${s}]="dd-dag-<DEWPOINT JOB ID>-app-pip-0${s}"
        done
fi

# Run array's through function
spacer=$'\n============\n'
response=$(verify_public_ip "mgmtip")
response=${response}${spacer}$(verify_public_ip "appip")

if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED${spacer}${response}"
else
    echo "PUBLIC IP CREATION PASSED${spacer}${response}"
fi