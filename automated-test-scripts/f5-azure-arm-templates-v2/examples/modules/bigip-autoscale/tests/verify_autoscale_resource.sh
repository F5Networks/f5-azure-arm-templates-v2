#!/usr/bin/env bash
#  expectValue = "AUTOSCALE SETTINGS PASSED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 5

# Script Requires min BASH Version 4
# usage: verify_insight_resource associative_array
# Array: [rule]="expected_value"
function verify_autoscale_resource() {
    local -n _arr=$1
    local autoscale_resource_object=$(az monitor autoscale show --name <RESOURCE GROUP>-autoscaleconfig --resource-group <RESOURCE GROUP> | jq -rc .)
    for r in "${!_arr[@]}";
    do
        local response=$(echo ${autoscale_resource_object} | jq -rc .$r)
        if echo "$response" | grep -q "${_arr[$r]}"; then
            rule_result="Rule:${r}    Response:$response   Value:${_arr[$r]}    PASSED"
        else
            rule_result="Rule:${r}    Response:$response   Value:${_arr[$r]}    FAILED"
        fi
        spacer=$'\n============\n'
        local results="${results}${rule_result}${spacer}"
    done
    echo "$results"
}

# Build associative security group arrays
# array_name[jq_filter]=expected_response
declare -A autoscale_settings
# verify custom email setting
autoscale_settings[notifications\[\].email.customEmails]='\<CUSTOM EMAIL>'

# verify capacity settings
autoscale_settings[profiles\[\].capacity.default]="<VM SCALE SET MIN COUNT>"
autoscale_settings[profiles\[\].capacity.minimum]="<VM SCALE SET MIN COUNT>"
autoscale_settings[profiles\[\].capacity.maximum]="<VM SCALE SET MAX COUNT>"

# verify autoscale rules when not using custom
if [ "<CUSTOM AUTOSCALE RULES>" == "[]" ]; then
    autoscale_settings[profiles\[\].rules\[0\].metricTrigger.metricName]="<CPU METRIC NAME>"
    autoscale_settings[profiles\[\].rules\[1\].metricTrigger.metricName]="<CPU METRIC NAME>"
    autoscale_settings[profiles\[\].rules\[2\].metricTrigger.metricName]="<THROUGHPUT METRIC NAME>"
    autoscale_settings[profiles\[\].rules\[3\].metricTrigger.metricName]="<THROUGHPUT METRIC NAME>"
    autoscale_settings[profiles\[\].rules\[0\].metricTrigger.threshold]="<SCALE OUT CPU THRESHOLD>"
    autoscale_settings[profiles\[\].rules\[1\].metricTrigger.threshold]="<SCALE IN CPU THRESHOLD>"
    autoscale_settings[profiles\[\].rules\[2\].metricTrigger.threshold]="<SCALE OUT THROUGHPUT THRESHOLD>"
    autoscale_settings[profiles\[\].rules\[3\].metricTrigger.threshold]="<SCALE IN THROUGHPUT THRESHOLD>"
    autoscale_settings[profiles\[\].rules\[0\].metricTrigger.timeWindow]="0:<SCALE OUT TIME WINDOW>:00"
    autoscale_settings[profiles\[\].rules\[1\].metricTrigger.timeWindow]="0:<SCALE IN TIME WINDOW>:00"
    autoscale_settings[profiles\[\].rules\[2\].metricTrigger.timeWindow]="0:<SCALE OUT TIME WINDOW>:00"
    autoscale_settings[profiles\[\].rules\[3\].metricTrigger.timeWindow]="0:<SCALE IN TIME WINDOW>:00"
else
    # verify autoscale rules when using custom
    # assumes json sent includes 4 triggers
    metric_name_0=$(echo '<CUSTOM AUTOSCALE RULES>' | jq -r .[0].metricTrigger.metricName)
    metric_name_1=$(echo '<CUSTOM AUTOSCALE RULES>' | jq -r .[1].metricTrigger.metricName)
    metric_name_2=$(echo '<CUSTOM AUTOSCALE RULES>' | jq -r .[2].metricTrigger.metricName)
    metric_name_3=$(echo '<CUSTOM AUTOSCALE RULES>' | jq -r .[3].metricTrigger.metricName)
    metric_threshold_0=$(echo '<CUSTOM AUTOSCALE RULES>' | jq -r .[0].metricTrigger.threshold)
    metric_threshold_1=$(echo '<CUSTOM AUTOSCALE RULES>' | jq -r .[1].metricTrigger.threshold)
    metric_threshold_2=$(echo '<CUSTOM AUTOSCALE RULES>' | jq -r .[2].metricTrigger.threshold)
    metric_threshold_3=$(echo '<CUSTOM AUTOSCALE RULES>' | jq -r .[3].metricTrigger.threshold)
    autoscale_settings[profiles\[\].rules\[0\].metricTrigger.metricName]="${metric_name_0}"
    autoscale_settings[profiles\[\].rules\[1\].metricTrigger.metricName]="${metric_name_1}"
    autoscale_settings[profiles\[\].rules\[2\].metricTrigger.metricName]="${metric_name_2}"
    autoscale_settings[profiles\[\].rules\[3\].metricTrigger.metricName]="${metric_name_3}"
    autoscale_settings[profiles\[\].rules\[0\].metricTrigger.threshold]="${metric_threshold_0}"
    autoscale_settings[profiles\[\].rules\[1\].metricTrigger.threshold]="${metric_threshold_1}"
    autoscale_settings[profiles\[\].rules\[2\].metricTrigger.threshold]="${metric_threshold_2}"
    autoscale_settings[profiles\[\].rules\[3\].metricTrigger.threshold]="${metric_threshold_3}"
    autoscale_settings[profiles\[\].rules\[0\].metricTrigger.timeWindow]="0:10:00"
    autoscale_settings[profiles\[\].rules\[1\].metricTrigger.timeWindow]="0:10:00"
    autoscale_settings[profiles\[\].rules\[2\].metricTrigger.timeWindow]="0:10:00"
    autoscale_settings[profiles\[\].rules\[3\].metricTrigger.timeWindow]="0:10:00"
fi
# verify autoscale output id
id=$(az deployment group show -n <RESOURCE GROUP> -g <RESOURCE GROUP> | jq -r .properties.outputs.autoscaleSettingsID.value)
autoscale_settings[id]="${id}"

# Run array's through function
response=$(verify_autoscale_resource "autoscale_settings")
spacer=$'\n============\n'

# Evaluate results
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "AUTOSCALE SETTINGS PASSED ${spacer}${response}"
fi