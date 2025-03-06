#!/bin/bash

# This needs to be a job so we can pull the dashboard route and apply it

echo -n 'Waiting for rhods-dashboard route'
while true; do
    dashboard_route="$(oc get route rhods-dashboard -n redhat-ods-applications -o jsonpath='{.spec.host}' 2>/dev/null)"
    echo -n .
    if [ -n "$dashboard_route" ]; then
        dashboard_route="https://${dashboard_route}"
        break
    fi
    sleep 5
done
echo

echo -n 'Waiting for KServe Access Token'
while true; do
    api_key="$(oc get secret access-model-sa -n $USER_PROJECT -ogo-template='{{ .data.token | base64decode }}' 2>/dev/null || :)"
    echo -n .
    if [ -n "$api_key" ]; then
        break
    fi
    sleep 5
done
echo

echo -n 'Waiting for public model route'
while true; do
    model_route="$(oc get route -n istio-system aligned-granite-${USER_PROJECT} -ojsonpath='{.status.ingress[0].host}' 2>/dev/null || :)"
    echo -n .
    if [ -n "$model_route" ]; then
        break
    fi
    sleep 5
done
echo

export dashboard_route \
    model_route \
    api_key \
    USER_NAME \
    USER_PROJECT \
    WORKBENCH_IMAGE

# This will read the file contents in the parent shell, then template them in
# the subshell with the variables inherited from the export, rendering them in
# the subshell output and allowing us to apply them from there.
for file in /app/*.yaml; do
    /bin/sh -c "cat << EOF
$(cat "$file")
EOF
" | oc apply -f-
done
