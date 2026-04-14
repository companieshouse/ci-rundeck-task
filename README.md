# ci-rundeck-task
Alpine based image for running Rundeck jobs as part of a Concourse pipeline.


## Example Usage

```yaml
---

groups:
- name: all
  jobs:
    - execute-rundeck-example-job

jobs:
- name: execute-rundeck-example-job
  plan:
  - task: run-job
    config:
      platform: linux

      image_resource:
        source:
          aws_access_key_id: ((my-aws-access-key-id))
          aws_secret_access_key: ((my-aws-secret-access-key))
          repository: ((my-docker-registry))/ci-rundeck-task
          tag: latest
        type: docker-image

      params:
        AUTH_TOKEN: this-is-a-pretend-api-token
        API_ENDPOINT: https://rundeck.host/api/41
        JOB_UUID: 9378ba10-1556-27f6-a296-37ce51f28e63
        JOB_PARAM_NAME_1: param1
        JOB_PARAM_VALUE_1: param1value
        JOB_PARAM_NAME_2: param2
        JOB_PARAM_VALUE_2: param2value
        JOB_PARAM_NAME_3: param3
        JOB_PARAM_VALUE_3: param3value
        JOB_PARAM_NAME_4: param4
        JOB_PARAM_VALUE_4: param4value
        JOB_PARAM_NAME_5: param5
        JOB_PARAM_VALUE_5: param5value
        TIMEOUT: 120

      run:
        path: bash
        args:
        - -ec
        - |
          /scripts/invoke-and-await-result.sh
```
