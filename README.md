# WIP

This repository is a work-in-progress and is not recommended for use in a POC until complete.

# Info

Vanilla configurations for a RHOAI instance to deploy a GenAI POC. This will deploy a variety of different required services including an LLM interface (AnythingLLM), a local S3 bucket, and other services needed for a GenAI POC on RHOAI.

# Deploy POC Scaffolding

Use the [RHDP](https://demo.redhat.com) catalog item named "GenAI POC RHOAI 2025." This catalog item will deploy an OpenShift cluster on AWS with the following configurations:
- publicly trusted TLS keys
- some basic users
- an NVIDIA GPU node
- A few operator installations
  - NVIDIA GPU Operator
  - OpenShift Pipelines
  - OpenShift Serverless (for KServe)
  - OpenShift Service Mesh (for KServe)
  - OpenShift GitOps

OpenShift GitOps is then wired up to use this repository by applying the [bootstrap ApplicationSet](basic-vanilla-poc/bootstrap/applicationset/applicationset-bootstrap.yaml).

One of the key elements for how this repository scaffolds your serving environment is that you need to move the model from wherever you trained it into the cluster. The synchronization from a source S3 bucket into the cluster is automated, and credentials need to be created in the cluster. An [example manifest](basic-vanilla-poc/bootstrap/model-deploy/example-src.yaml) has been provided. You will need to modify the values to represent your actual model source, whether it be an existing S3 bucket in Amazon or the S3 compatible endpoint to IBM COS, where your models should be delivered after the alignment tuning process. You can apply this manifest, after updating with your values, using either the command line or by copying and pasting it into the OpenShift console's "➕" button in the top right.

If you need to manually upload model files, for example having downloaded them from IBM COS in the browser or trained the model using an alternate method, you can still take advantage of the automation for standing up the inference service. Uploading local files or recursively uploading a local directory containing the model files can be accomplished with a helper script available in this repository. For instructions on its use, see the section on [Using the S3 Upload Automation](#using-the-s3-upload-automation).

If you have manually synchronized the model, whether using the provided local upload tool or simply `s3cmd` and the public S3 endpoint, you can instead apply a flag in that secret to abort the sync early, allowing the model rollout to proceed. A manifest you can use, in the same way described above, is available [here](basic-vanilla-poc/bootstrap/model-deploy/example-src-local.yaml). Don't apply this manifest until the upload is finished, as triggering the rollout before the model is in place will require restarting some services (like the KServe predictor).

## Using the S3 Upload Automation

There are a few prerequisites to running the upload automation successfully.

1. Linux or MacOS system. Windows users should be able to use WSL.
1. Have a valid local [kubeconfig](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/) file. If you have `oc` installed locally, and are logged in using the normal means, this will be located at `~/.kube/config`. If you're using the `KUBECONFIG` environment variable to point to an alternate location, this will be respected.
1. Have `podman` installed and configured properly. If you're on a M-series Mac, for example, ensure that your `podman-machine` configuration is functional.
1. Have this repository either `git clone`'d or downloaded and unarchived.

To use the uploader:

1. Open a terminal to the location of your desired upload files. They don't need to be adjacent to the uploader, but you need to know the path to the repository you downloaded. You should be able to run `ls` and see the files, or a directory containing the files.
1. Run `upload.sh` from this repository and provide one or more relative paths to the files you want uploaded. For directories that you'd like to be fed directly to the model parent key in the bucket, include a trailing slash.

> [!WARNING]
> You must be in the correct directory, and only use a relative path that is a child of that directory, when using the uploader. It will use both of these pieces of information to ensure that the model files are available to upload from inside a container.

For example, suppose you have the following directory structure:

```
/home/user/
├── Downloads
│   └── aligned-model
│       ├── config.json
│       └── example.safetensors
└── genai-rhoai-poc-template
    └── hack
        ├── overlay
        └── upload.sh
```

You would want to run:

```
cd ~/Downloads
ls
```

`aligned-model`

```
ls aligned-model
```

`config.json  example.safetensors`

```
~/genai-rhoai-poc-template/hack/upload.sh aligned-model/
```

`Building/updating image.`\
`Connecting to cluster: https://api.cluster.example.com:6443`\
`Recovering Data Connection information (when available from the cluster).`\
`+ /usr/local/bin/s3cmd -c /tmp/s3cfg put --recursive aligned-model/ s3://demo-64d3c912-dd41-4ec5-bf3a-cff4895655b0/models/`\
`upload: 'aligned-model/config.json' -> 's3://demo-64d3c912-dd41-4ec5-bf3a-cff4895655b0/models/config.json'  [1 of 2]`\
` 518 of 518   100% in    0s  1306.29 B/s  done`\
`upload: 'aligned-model/example.safetensors' -> 's3://demo-64d3c912-dd41-4ec5-bf3a-cff4895655b0/models/example.safetensors'  [2 of 2]`\
` 1588 of 1588   100% in    0s     9.51 KB/s  done`\
`+ /usr/local/bin/s3cmd -c /tmp/s3cfg ls s3://demo-64d3c912-dd41-4ec5-bf3a-cff4895655b0/models/`\
`2025-01-20 16:19          518  s3://demo-64d3c912-dd41-4ec5-bf3a-cff4895655b0/models/config.json`\
`2025-01-20 16:19         1588  s3://demo-64d3c912-dd41-4ec5-bf3a-cff4895655b0/models/example.safetensors`

At the end of this process, apply [the manifest](basic-vanilla-poc/bootstrap/model-deploy/example-src-local.yaml) to indicate that the local upload is complete as described above.
