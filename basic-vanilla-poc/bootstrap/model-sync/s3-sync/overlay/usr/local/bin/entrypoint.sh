#!/bin/bash

if "${S3_SYNC_LOCAL_UPLOAD_COMPLETE:-false}" >/dev/null 2>&1; then
    echo "Skipping sync as upload marked complete"
    exit 0
fi

if "${S3_SYNC_USE_IBMCLOUD_CLI:-false}" >/dev/null 2>&1; then
    echo "Not yet implemented!" >&2
    exit 1
else
    exec s3-sync "${@}"
fi
