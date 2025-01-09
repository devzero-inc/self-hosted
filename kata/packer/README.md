# Create AMIs using packer
## Download resources from S3 bucket
```bash
aws s3 cp s3://dz-pvm-artifacts/ . --recursive
```

Run this in engineering environment.
```bash
export AWS_PROFILE=engineering
packer init .
packer build .
```
