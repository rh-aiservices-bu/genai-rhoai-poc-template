# Model Synchronization

The automation hangs in between the First and Last phases, waiting for model synchronization to complete before it can continue. The hanging, on a freshly provisioned cluster, occurs because a Kubernetes Secret has been specified as an Environment Variable source for a Kubernetes Job, and that Secret is not deployed by the automation. The content of that secret determines how the Job behaves. The Last phase of automation expects that completion of this Job means that the model has been completely uploaded to the ObjectBucketClaim's defined Bucket under the subdirectory `models/`.

There are several ways to do this, with three of the ones documented below requiring that you download the model to your workstation and two of them only requiring that your provide the credentials and configuration to access the model and allow the Job to perform the synchronization from directly inside the PoC cluster. Use whichever one works based on where your model is, what credentials you have access to, and whatever you're more comfortable with.

## Model Synchronization Options

1. [From a source S3 bucket](#source-s3-bucket-aws-s3-ibm-cos-with-a-service-account-etc) (synchronize inside cluster)
1. [From IBM COS via temporary passcode](#from-ibm-cos-via-temporary-passcode) (synchronize inside cluster)
1. [Local files via CLI (with automation)](#local-files-via-cli-with-automation) (uploaded from your workstation)
1. [Local files via ODH TECH upload](#local-files-via-odh-tec-upload) (uploaded from your workstation)
1. [Local files manually](#local-files-manually) (uploaded from your workstation)

### Source S3 bucket (AWS S3, IBM COS with a Service Account, etc.)

TODO

### IBM COS via temporary passcode

TODO

### Local files via CLI (with automation)

TODO

### Local files via ODH TEC upload

TODO

### Local files manually

TODO
