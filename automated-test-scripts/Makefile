#!make
current_dir := $(shell pwd)
# Create an environmental script and refernce it here (.gitignore set to ignore env.sh)
# example: export GOOGLE_PROJECT_ID=my_project_id
# option 1 all env variables refrenced in rules need be defined in env.sh
# option 2 have env vars set prior to running make rule
include env.sh
.PHONY: help
help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo " 'azure_network_mod' using dewdrop docker image:stable, runs standalone test defined in env varable AZURE_TEMPLATE_TEST_URL/AZURE_TEMPLATE_TEST_PARMS"
	@echo " 'azure_autoscale_v2' using dewdrop docker image:stable, runs standalone test defined in env varable AZURE_TEMPLATE_TEST_URL_API/AZURE_TEMPLATE_TEST_PARAMS_API"

.PHONY: gce
env:
	env
# Azure V2
azure_network_mod:
	docker run -it -v ${current_dir}:/automated-test-scripts -v ${current_dir}/../examples:/examples -e SSH_KEY="${DEWPT_PRIVATE_KEY}" -e AZURE_TENANT_ID="${AZURE_TENANT_ID}" -e AZURE_CLIENT_ID="${AZURE_CLIENT_ID}" -e AZURE_SERVICE_PRINCIPAL="${AZURE_SERVICE_PRINCIPAL}" -e STACK_TYPE="${STACK_TYPE}" -e AZURE_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID}" -e TEMPLATE_URL="${AZURE_TEMPLATE_TEST_URL_NET_MOD}" -e TEMPLATE_PARAMETERS="${AZURE_TEMPLATE_TEST_PARAMS_NET_MOD}" artifactory.f5net.com/ecosystems-cloudsolutions-docker-dev/dewdrop:stable
azure_access_mod:
	docker run -it -v ${current_dir}:/automated-test-scripts -v ${current_dir}/../examples:/examples -e SSH_KEY="${DEWPT_PRIVATE_KEY}" -e AZURE_TENANT_ID="${AZURE_TENANT_ID}" -e AZURE_CLIENT_ID="${AZURE_CLIENT_ID}" -e AZURE_SERVICE_PRINCIPAL="${AZURE_SERVICE_PRINCIPAL}" -e STACK_TYPE="${STACK_TYPE}" -e AZURE_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID}" -e TEMPLATE_URL="${AZURE_TEMPLATE_TEST_URL_ACCESS_MOD}" -e TEMPLATE_PARAMETERS="${AZURE_TEMPLATE_TEST_PARAMS_ACCESS_MOD}" artifactory.f5net.com/ecosystems-cloudsolutions-docker-dev/dewdrop:stable
azure_dag_mod:
	docker run -it -v ${current_dir}:/automated-test-scripts -v ${current_dir}/../examples:/examples -e SSH_KEY="${DEWPT_PRIVATE_KEY}" -e AZURE_TENANT_ID="${AZURE_TENANT_ID}" -e AZURE_CLIENT_ID="${AZURE_CLIENT_ID}" -e AZURE_SERVICE_PRINCIPAL="${AZURE_SERVICE_PRINCIPAL}" -e STACK_TYPE="${STACK_TYPE}" -e AZURE_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID}" -e TEMPLATE_URL="${AZURE_TEMPLATE_TEST_URL_DAG_MOD}" -e TEMPLATE_PARAMETERS="${AZURE_TEMPLATE_TEST_PARAMS_DAG_MOD}" artifactory.f5net.com/ecosystems-cloudsolutions-docker-dev/dewdrop:stable
azure_bigip_mod:
	docker run -it -v ${current_dir}:/automated-test-scripts -v ${current_dir}/../examples:/examples -e SSH_KEY="${DEWPT_PRIVATE_KEY}" -e AZURE_TENANT_ID="${AZURE_TENANT_ID}" -e AZURE_CLIENT_ID="${AZURE_CLIENT_ID}" -e AZURE_SERVICE_PRINCIPAL="${AZURE_SERVICE_PRINCIPAL}" -e AZURE_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID}" -e TEMPLATE_URL="${AZURE_TEMPLATE_TEST_URL_BIGIP_MOD}" -e TEMPLATE_PARAMETERS="${AZURE_TEMPLATE_TEST_PARAMS_BIGIP_MOD}" artifactory.f5net.com/ecosystems-cloudsolutions-docker-dev/dewdrop:stable
azure_functional_mod:
	docker run -it -v ${current_dir}:/automated-test-scripts -v ${current_dir}/../examples:/examples -e SSH_KEY="${DEWPT_PRIVATE_KEY}" -e AZURE_TENANT_ID="${AZURE_TENANT_ID}" -e AZURE_CLIENT_ID="${AZURE_CLIENT_ID}" -e AZURE_SERVICE_PRINCIPAL="${AZURE_SERVICE_PRINCIPAL}" -e AZURE_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID}" -e TEMPLATE_URL="${AZURE_TEMPLATE_TEST_URL_FUNCTIONAL_MOD}" -e TEMPLATE_PARAMETERS="${AZURE_TEMPLATE_TEST_PARAMS_FUNCTIONAL_MOD}" artifactory.f5net.com/ecosystems-cloudsolutions-docker-dev/dewdrop:stable
azure_autoscale_v2:
	docker run -it -v ${current_dir}:/automated-test-scripts -v ${current_dir}/../examples:/examples -e SSH_KEY="${DEWPT_PRIVATE_KEY}" -e AZURE_TENANT_ID="${AZURE_TENANT_ID}" -e AZURE_CLIENT_ID="${AZURE_CLIENT_ID}" -e AZURE_SERVICE_PRINCIPAL="${AZURE_SERVICE_PRINCIPAL}" -e AZURE_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID}" -e TEMPLATE_URL="${AZURE_TEMPLATE_TEST_URL_AUTOSCALE_V2}" -e TEMPLATE_PARAMETERS="${AZURE_TEMPLATE_TEST_PARAMS_AUTOSCALE_V2}" artifactory.f5net.com/ecosystems-cloudsolutions-docker-dev/dewdrop:stable
azure_autoscale_bigiq_v2:
	docker run -it -v ${current_dir}:/automated-test-scripts -v ${current_dir}/../examples:/examples -e SSH_KEY="${DEWPT_PRIVATE_KEY}" -e AZURE_TENANT_ID="${AZURE_TENANT_ID}" -e AZURE_CLIENT_ID="${AZURE_CLIENT_ID}" -e AZURE_SERVICE_PRINCIPAL="${AZURE_SERVICE_PRINCIPAL}" -e AZURE_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID}" -e TEMPLATE_URL="${AZURE_TEMPLATE_TEST_URL_AUTOSCALE_BIGIQ_V2}" -e TEMPLATE_PARAMETERS="${AZURE_TEMPLATE_TEST_PARAMS_AUTOSCALE_BIGIQ_V2}" artifactory.f5net.com/ecosystems-cloudsolutions-docker-dev/dewdrop:stable
