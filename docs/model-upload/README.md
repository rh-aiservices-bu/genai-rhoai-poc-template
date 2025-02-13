# Model Synchronization

The automation hangs in between the First and Last phases, waiting for model synchronization to complete before it can continue. The hanging, on a freshly provisioned cluster, occurs because a Kubernetes Secret has been specified as an Environment Variable source for a Kubernetes Job named `synchronize-model`. That Secret is not deployed by the automation. The content of that secret determines how the Job behaves. The Last phase of automation expects that completion of this Job means that the model has been completely uploaded to the ObjectBucketClaim's defined Bucket under the subdirectory `models/`.

There are several ways to get the job to complete, with three of the ones documented below requiring that you download the model to your workstation and two of them only requiring that your provide the credentials and configuration to access the model hosted somewhere accessible to the cluster, allowing the Job to perform the synchronization from directly inside the PoC cluster. Use whichever one works based on where your model is, what credentials you have access to, and whatever you're more comfortable with.

## Creating the Secret

To create the `model-source` Secret in the `demo` namespace, as any of the following methods require, you can edit one of the examples provided (and linked below where appropriate) and then use the `oc apply -f path/to/secret.yaml` or similar, if logged in on the command line. You can also copy the content of the Secret from the repository, use the ![plus](images/plus.png) button in the top right of the OpenShift Console to access the "Import YAML" page, and then paste the secret content there before editing it to match the values you desire and clicking ![create](images/create.png).

## Model Synchronization Options

1. [From a source S3 bucket](#source-s3-bucket-aws-s3-ibm-cos-with-a-service-account-etc) (synchronize inside cluster)
1. [From IBM COS via temporary passcode](#from-ibm-cos-via-temporary-passcode) (synchronize inside cluster)
1. [Local files via CLI (with automation)](#local-files-via-cli-with-automation) (uploaded from your workstation)
1. [Local files via ODH TECH upload](#local-files-via-odh-tec-upload) (uploaded from your workstation)
1. [Local files manually](#local-files-manually) (uploaded from your workstation)

### Source S3 bucket (AWS S3, IBM COS with a Service Account, etc.)

Your `model-source` Secret needs to contain the S3 credentials (and optionally the endpoint) of your source, the bucket the model is in, and any prefixes to the S3 key of the model files.

[Example S3 Secret](example-src-s3.yaml).

In this example, there is a bucket in AWS region `us-east-1` named `bucket`, and the model files are uploaded as, for example, `s3://bucket/folder/config.json` and `s3://bucket/folder/model-00001-of-00004.safetensors` etc. STS and other more robust authentication methods are not supported for this.

When this secret is created (using the methods described [above](#creating-the-secret)), with correct details for the model source, the `synchronize-model` job will synchronize the model directly from the source bucket into the on-cluster MCGW-backed bucket, allowing automation to continue with the Last phase.

### IBM COS via temporary passcode

Your `model-source` Secret needs to contain the information about the IBM COS instance you're using, the COS bucket for your model files, the key prefix for those files specifically, and an IBM COS temporary passcode (these expire quick!).

[Example IBM COS Secret](example-src-ibm.yaml).

To get the information needed to update the Secret:

1. Navigate to the ![Aligned models](images/aligned-models.png) page
1. Find your model in the list and click ![Open](images/model-open.png) in the Object storage column
1. The Filter bar (![filter bar](images/filter-bar.png)) above your objects is pre-populated with the prefix for your model files inside the bucket. You need to update the Secret with this value, so copy it.
    - `S3_SYNC_COS_MODEL_PREFIX` should be updated to reflect this value
1. Click on ![Configuration](images/instance-configuration.png) in the navigation bar under the bucket name
1. In the `Bucket Details` section, recover the following:
    - ![bucket-details](images/bucket-details.png)
1. In the Secret, you'll need to update the following:
    - `S3_SYNC_COS_INSTANCE_REGION` with the region called out
    - `S3_SYNC_COS_BUCKET` with the bucket name called out
    - `S3_SYNC_COS_INSTANCE_CRN` with the Bucket CRN
1. When you are prepared to create the Secret with these updates, it's time to recover the temporary passcode for signing in. This passcode is only valid for five minutes, so you'll want to create the Secret very quickly after getting this temporary passcode.
    1. In the very top-right of the IBM Cloud navigation bar, click the Profile icon (![profile icon](images/profile-icon.png))
    1. Select "Log in to CLI and API" from the menu
    1. Copy the one time passcode, only, without any extra flags, from any of the fields on the dialog, to update the Secret
        - ![one time passcode](images/log-in-passcode.png)
        - `S3_SYNC_COS_TEMPORARY_PASSCODE` updated with this value
1. Create the secret using the methods described [above](#creating-the-secret)

### Local files via CLI (with automation)

TODO

### Local files via ODH TEC upload

TODO

### Local files manually

TODO
