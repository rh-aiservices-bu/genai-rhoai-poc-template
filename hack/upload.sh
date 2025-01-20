#!/bin/bash

set -e

echo -n "Building/updating image"
podman build --pull=newer --quiet "$(dirname "$(realpath "$0")")/s3-upload" -t localhost/s3-upload:latest >/dev/null 2>&1
echo .

if [ -n "$KUBECONFIG" ]; then
    kube_mount=(-v "$KUBECONFIG:/s3cmd/.kube/config")
else
    kube_mount=(-v ~/.kube:/s3cmd/.kube)
fi

podman run --rm -it --security-opt=label=disable "${kube_mount[@]}" -v "${PWD}:/workspace" localhost/s3-upload:latest "${@}"
