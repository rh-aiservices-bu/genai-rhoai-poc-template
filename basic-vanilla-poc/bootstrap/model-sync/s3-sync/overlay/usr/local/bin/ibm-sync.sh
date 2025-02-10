#!/bin/bash
set -e

function logcmd {
    set -x
    "${@}"
    { set +x; } 2>/dev/null
}
logcmd ibmcloud plugin install -f cloud-object-storage
logcmd ibmcloud config --check-version=false

if [ -n "$S3_SYNC_COS_TEMPORARY_PASSCODE" ]; then
    echo "+ ibmcloud login -a https://cloud.ibm.com -u passcode -p <censored>" >&2
    ibmcloud login -a https://cloud.ibm.com -u passcode -p "${S3_SYNC_COS_TEMPORARY_PASSCODE}"
fi

if [ -n "$S3_SYNC_COS_INSTANCE_CRN}" ]; then
    logcmd ibmcloud cos config crn --crn "${S3_SYNC_COS_INSTANCE_CRN}"
fi

common_args=(--bucket ${S3_SYNC_COS_BUCKET} --region ${S3_SYNC_COS_INSTANCE_REGION})
list_args=("${common_args[@]}")
if [ -n "$S3_SYNC_COS_MODEL_PREFIX" ]; then
    list_args+=(--prefix "${S3_SYNC_COS_MODEL_PREFIX}")
fi
list_args+=(--output json)

mkdir -p download
logcmd cd download
while read -r object; do
    logcmd ibmcloud cos download "${common_args[@]}" --key "$object"
done < <(logcmd ibmcloud cos list-objects-v2 "${list_args[@]}" | logcmd jq -r '.Contents[].Key')

# Create some useful variables for s3cfg
scheme=$(echo "$AWS_S3_ENDPOINT" | cut -d: -f1)
s3_host=$(echo "$AWS_S3_ENDPOINT" | cut -d/ -f3-)
if [ "$scheme" = "http" ]; then
    use_https=False
else
    use_https=True
fi

cat <<EOF >/workdir/.s3cfg
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

dest="s3://${AWS_S3_BUCKET}/models/"
logcmd s3cmd sync --no-delete-removed ./ "$dest"
logcmd s3cmd ls "$dest"
