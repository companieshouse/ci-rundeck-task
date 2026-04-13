#!/bin/bash

# Executes a RunDeck job using the following environment variables:
#
# Required:
# API_ENDPOINT - this is the URL to the Rundeck API endpoint - e.g. https://rundeck.mydomain.com/api/41
# JOB_UUID - this is the UUID of the job to execute - e.g. 91441a10-1856-47f6-2186-47ce90c28e72
# AUTH_TOKEN - the authentication token to use in the API call - e.g. blahsecretblahsecretblahsecret
# 
# 
# Optional:
# TIMEOUT - the number of seconds to wait for the job to succeed or fail, before timing out - default is 300
# JOB_PARAM_NAME_1 - the name of a job parameter that should be passed when invoking the job - e.g. "param1"
# JOB_PARAM_VALUE_1 - the value of the job parameter that should be passed when invoking the job - e.g. "param1value"
# JOB_PARAM_NAME_2/JOB_PARAM_VALUE_2 through to JOB_PARAM_NAME_5/JOB_PARAM_VALUE_5 - further job parameters that should be passed (up to 5 supported)
# 
# The job is invoked by an HTTPS POST to the Rundeck API which returns the execution id.
# The status of the job is then checked using the API until it has completed successfully (state = SUCCEEDED), or fails (state = FAILED) or the timeout is reached.
# Exit code 0 is returned is the job succeeds, 1 is returned if the job fails and 2 is returned if there is a timeout. 

check_for_api_error() {
    if [[ $1 -gt 0 ]]; then                                  
        log-output error "Failed to call Rundeck API - curl returned code $1"
        cat stdout
        exit 1
    fi

    ERROR_FROM_API=$(jq ".errorCode // empty" bodyout)
    if [[ ! -z ${ERROR_FROM_API} ]]; then
        log-output error "Error received from API"
        cat bodyout | jq
        exit 1
    fi
}

process_environment_vars() {
    mandatory=(
        API_ENDPOINT
        JOB_UUID
        AUTH_TOKEN
    )

    for variable in "${mandatory[@]}"; do
        if [[ -z "$(printenv ${variable})" ]]; then
            log-output error "Mandatory variable missing: [${variable}]"
            missing_mandatory_vars="true"
        fi
    done

    if [[ "${missing_mandatory_vars}" == "true" ]]; then
        exit 1
    fi

    log-output info "Processing job param env vars to form JOB_ARGUMENTS var"
    [[ ! -z ${JOB_PARAM_NAME_1} ]] && JOB_ARGUMENTS="-${JOB_PARAM_NAME_1} ${JOB_PARAM_VALUE_1}"
    [[ ! -z ${JOB_PARAM_NAME_2} ]] && JOB_ARGUMENTS="${JOB_ARGUMENTS} -${JOB_PARAM_NAME_2} ${JOB_PARAM_VALUE_2}"
    [[ ! -z ${JOB_PARAM_NAME_3} ]] && JOB_ARGUMENTS="${JOB_ARGUMENTS} -${JOB_PARAM_NAME_3} ${JOB_PARAM_VALUE_3}"
    [[ ! -z ${JOB_PARAM_NAME_4} ]] && JOB_ARGUMENTS="${JOB_ARGUMENTS} -${JOB_PARAM_NAME_4} ${JOB_PARAM_VALUE_4}"
    [[ ! -z ${JOB_PARAM_NAME_5} ]] && JOB_ARGUMENTS="${JOB_ARGUMENTS} -${JOB_PARAM_NAME_5} ${JOB_PARAM_VALUE_5}"
    log-output info "JOB_ARGUMENTS=${JOB_ARGUMENTS}"
}

call_rundeck_api() {
    log-output info "Calling Rundeck API to invoke job ${API_ENDPOINT}/job/${JOB_UUID}/run"
    curl -s -m 10 -X POST \
        -H "Content-Type: application/json"
        -H "Accept: application/json"
        -H "X-Rundeck-Auth-Token: ${AUTH_TOKEN}"
        -d "{'argString':'${JOB_ARGUMENTS}'}" \
        "${API_ENDPOINT}/job/${JOB_UUID}/run" \
        -o bodyout > stdout

    check_for_api_error $?

    # Get the permalink from the output
    PERMALINK=$(jq -r .permalink bodyout)
    log-output info "The job execution can be followed in Rundeck at ${PERMALINK}"

    # Get the execution id from the output
    EXECUTION_ID=$(jq .id bodyout)

    # Loop and check state of job until SUCCEEDED or FAILED or our TIMEOUT is exceeded
    TIMEOUT=${TIMEOUT:-300}
    while [[ ${EXECUTION_STATE} != "SUCCEEDED" ]]; do
        log-output info "Checking status of execution id ${EXECUTION_ID}"
        curl -s -m 10 \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -H "X-Rundeck-Auth-Token: ${AUTH_TOKEN}" \
            "${API_ENDPOINT}/execution/${EXECUTION_ID}/state" \
            -o bodyout > stdout

        check_for_api_error $?

        # Get the status from the output
        EXECUTION_STATE=$(jq -r .executionState bodyout)
        log-output info "EXECUTION_STATE=${EXECUTION_STATE} after ${SECONDS} seconds"

        if [[ ${EXECUTION_STATE} == "FAILED" ]]; then
            log-output error "Execution ${EXECUTION_ID} FAILED"
            cat bodyout | jq
            exit 1
        fi

        if [[ ${EXECUTION_STATE} != "SUCCEEDED" ]]; then
            if [[ ${SECONDS} -lt ${TIMEOUT} ]]; then
                sleep 5
            else
                log-output error "Timed out after ${TIMEOUT} seconds"
                exit 2
            fi
        fi
    done
}

# Entrypoint
process_environment_vars
call_rundeck_api
