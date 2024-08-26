# eks-openobserve

Guide on installing OpenObserve on Amazon EKS

## Install eksctl and create an EKS cluster (Skip if EKS cluster already exists)

Installation guide for eksctl at: https://eksctl.io/installation/

Create EKS cluster

```shell
eksctl create cluster -f o2-eks.yaml
```

## Install Helm (If not already installed)

Follow instructions at https://helm.sh/docs/intro/install/

## Create s3 Bucket and IAM Policy, Role for OpenObserve

```shell
wget https://raw.githubusercontent.com/openobserve/eks-openobserve/main/bucket.sh
chmod +x bucket.sh
./bucket.sh
```

## Download values.yaml file

```shell
wget https://raw.githubusercontent.com/openobserve/openobserve-helm-chart/main/charts/openobserve/values.yaml
```

## Update values.yaml file

1. Update the `serviceAccount` section with the ARN of the IAM role created in the previous step
2. Update the bucket name
3. Update the credentials

## Install OpenObserve

### Setup prerequisites

Install CloudNativePG operator (Use this if you are not using Amazon RDS. RDS is highly recommended due to its easy management and maintenance)

```shell

kubectl apply --server-side -f \
  https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/main/releases/cnpg-1.24.0.yaml
```

Create a StorageClass for gp3 volumes

```shell
kubectl apply -f https://raw.githubusercontent.com/openobserve/eks-openobserve/main/gp3_storage_class.yaml
```

### Add OpenObserve Helm repository

```shell
helm repo add openobserve https://openobserve.github.io/openobserve-helm-chart
helm repo update
```

### Install OpenObserve

```shell
kubectl create ns openobserve

helm --namespace openobserve -f values.yaml install o2 openobserve/openobserve
```
