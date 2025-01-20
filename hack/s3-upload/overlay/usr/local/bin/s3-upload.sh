#!/bin/bash

set -e

# Ensure we're logged in
if ! oc whoami >/dev/null 2>&1; then
    echo "You don't appear to be logged in to an OpenShift cluster inside the container." >&2
    exit 1
fi

echo -n "Connecting to cluster: "
oc whoami --show-server

# Recover the bucket secret
eval "$(
    { oc get secret -n demo demo-models -ojson 2>/dev/null || :; } |
        { jq -r '.data | to_entries | map_values(@sh "export \(.key)=\(.value | @base64d)")[]' || :; }
)"

# Modify our endpoint to use the external route
if [ "${AWS_S3_ENDPOINT}" = "http://s3.openshift-storage.svc" ]; then
    export AWS_S3_ENDPOINT="https://$(oc get route.route -n openshift-storage s3 -ojsonpath='{.status.ingress[0].host}')"
fi

scheme=$(echo "$AWS_S3_ENDPOINT" | cut -d: -f1)
s3_host=$(echo "$AWS_S3_ENDPOINT" | cut -d/ -f3-)
if [ "$scheme" = "http" ]; then
    use_https=False
else
    use_https=True
fi

cat <<EOF >/tmp/s3cfg
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
    /usr/local/bin/s3cmd -c /tmp/s3cfg "${@}"
}
dest="s3://${AWS_S3_BUCKET}/models/"

for input in "${@}"; do
    if [ -d "$input" ]; then
        set -x
        s3cmd put --recursive "${input%/}/" "$dest"
        { set +x; } 2>/dev/null
    else
        set -x
        s3cmd put "${input}" "$dest"
        { set +x; } 2>/dev/null
    fi
done

set -x
s3cmd ls "$dest"
