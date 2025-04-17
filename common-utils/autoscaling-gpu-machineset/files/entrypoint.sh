#!/bin/bash

echo -n 'Waiting for information on MachineSets to be available'
while true; do
    read INFRA_ID AWS_AMI AWS_AZ AWS_REGION < <(
        oc get machineset -ogo-template='
            {{- $last := len (slice (printf "%*s" (len .items) "") 1) }}
            {{- $machine := (index .items $last).spec.template }}
            {{- $infra_id := (index $machine.metadata.labels "machine.openshift.io/cluster-api-cluster") }}
            {{- $ami := $machine.spec.providerSpec.value.ami.id }}
            {{- $placement := $machine.spec.providerSpec.value.placement }}
            {{- $infra_id }} {{ $ami }} {{ $placement.availabilityZone }} {{ $placement.region -}}
        '
    )
    echo -n .
    if [ -n "$INFRA_ID" ]; then
        break
    fi
    sleep 5
done
echo

export INFRA_ID AWS_AMI AWS_AZ AWS_REGION

# This will read the file contents in the parent shell, then template them in
# the subshell with the variables inherited from the export, rendering them in
# the subshell output and allowing us to apply them from there.
for file in /app/*.yaml; do
    /bin/sh -c "cat << EOF
$(cat "$file")
EOF
" | oc apply -f-
done
