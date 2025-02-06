#!/bin/bash

set -e

# Ensure we're logged in
if ! oc whoami >/dev/null 2>&1; then
    echo "You don't appear to be logged in to an OpenShift cluster inside the container. Check the docs for prerequisites!" >&2
    exit 1
fi

paths_to_upload=()

function show_usage {
    echo "usage: upload.sh PATH [PATH [...]]" >&2
}

while (("${#}" > 0)); do
    case "$1" in
    *)
        if [ -d "$1" ]; then
            paths_to_upload+=("$1")
        else
            echo "Non-directory path provided: $1" >&2
            show_usage
            exit 1
        fi
        ;;
    esac
    shift
done

if ((${#paths_to_upload} < 1)); then
    show_usage
    exit 0
fi

echo -n "Connecting to cluster: "
oc whoami --show-server

# Recover the bucket secret
echo -n "Recovering Data Connection information (when available from the cluster)"
while true; do
    eval "$(
        { oc get secret -n demo demo-models -ojson 2>/dev/null || :; } |
            { jq -r '.data | to_entries | map_values(@sh "export \(.key)=\(.value | @base64d)")[]' || :; }
    )"
    if [ -n "$AWS_S3_BUCKET" ]; then
        echo .
        break
    fi
    echo -n .
    sleep 1
done

# Modify our endpoint to use the external route
if [ "${AWS_S3_ENDPOINT}" = "http://s3.openshift-storage.svc" ]; then
    export AWS_S3_ENDPOINT="https://$(oc get route.route -n openshift-storage s3 -ojsonpath='{.status.ingress[0].host}')"
fi

# Create some useful variables for s3cfg
scheme=$(echo "$AWS_S3_ENDPOINT" | cut -d: -f1)
s3_host=$(echo "$AWS_S3_ENDPOINT" | cut -d/ -f3-)
if [ "$scheme" = "http" ]; then
    use_https=False
else
    use_https=True
fi

cat <<EOF >/s3cmd/.s3cfg
[default]
check_ssl_certificate = True
check_ssl_hostname = True
connection_pooling = True
guess_mime_type = True
use_mime_magic = True
access_key = ${AWS_ACCESS_KEY_ID}
secret_key = ${AWS_SECRET_ACCESS_KEY}
bucket_location = ${AWS_DEFAULT_REGION}
host_base = ${s3_host}
host_bucket = ${s3_host}
use_https = ${use_https}
EOF

function s3cmd {
    set -x
    /usr/local/bin/s3cmd "${@}"
    { set +x; } 2>/dev/null
}
dest="s3://${AWS_S3_BUCKET}/models/"

# Upload directories recursively, using
for input in "${paths_to_upload[@]}"; do
    s3cmd sync --no-delete-removed "$input" "$dest"
done

s3cmd ls "$dest"
