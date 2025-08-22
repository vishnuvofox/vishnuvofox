# FHIR AWS Infrastructure – Terraform IaC

This repository provisions a complete FHIR system architecture using Terraform modules for serverless and supporting AWS resources.
```bash
Directory structure:
└── fhir/
    ├── main.tf
    ├── variables.tf
    ├── certs/
    │   ├── ca-cert.pem
    │   └── ca-key.pem
    ├── deployment/
    │   ├── kustomization.yml
    │   ├── nifi/
    │   │   ├── 00-rbac.yml
    │   │   ├── 01-configmap.yml
    │   │   ├── 02-configmap-ssl.yml
    │   │   ├── 03-statefulset.yml
    │   │   ├── 04-network.yml
    │   │   ├── 05-autoscale.yml
    │   │   ├── 06-publish.yml
    │   │   ├── ca.yaml
    │   │   └── kustomization.yml
    │   └── zookeeper/
    │       ├── app.yml
    │       └── kustomization.yml
    └── modules/
        ├── api_gateway/
        │   ├── main.tf
        │   ├── outputs.tf
        │   └── variables.tf
        ├── cloudfront/
        │   ├── main.tf
        │   └── variables.tf
        ├── cloudfront_oais/
        │   ├── main.tf
        │   ├── outputs.tf
        │   └── variables.tf
        ├── cognito/
        │   ├── main.tf
        │   └── variables.tf
        ├── ec2/
        │   ├── main.tf
        │   ├── variables.tf
        │   ├── vofox
        │   └── vofox.pub
        ├── eks/
        │   ├── main.tf
        │   ├── outputs.tf
        │   └── variables.tf
        ├── iam/
        │   ├── main.tf
        │   ├── outputs.tf
        │   └── variables.tf
        ├── lambda/
        │   ├── fhir_api_handler.zip
        │   ├── main.tf
        │   ├── outputs.tf
        │   └── variables.tf
        ├── networking/
        │   ├── main.tf
        │   ├── outputs.tf
        │   └── variables.tf
        ├── rds/
        │   ├── main.tf
        │   ├── outputs.tf
        │   └── variables.tf
        ├── sqs/
        │   ├── main.tf
        │   ├── outputs.tf
        │   └── variables.tf
        └── storage/
            ├── main.tf
            ├── outputs.tf
            ├── variables.tf
            ├── fhir-blockly/
            │   ├── default.xml
            │   ├── index.html
            │   └── assets/
            │       ├── _commonjsHelpers-Cpj98o6Y.js
            │       ├── bi_blockly-cfbj7yJm.js
            │       ├── bi_blockly-JU1Ofyci.js
            │       ├── browser-raw-P5HygWKU.js
            │       ├── index-CAfrDKHo.css
            │       ├── index-CGc0dV5S.js
            │       └── javascript_compressed-CViLVm5f.js
            └── fhir-ui/
                ├── index.html
                ├── assets/
                │   ├── components-4536c838.css
                │   ├── components-fee8c5d0.js
                │   ├── index-1e6c6213.js
                │   ├── index-ebfaaed0.css
                │   ├── not-found-ac9fc911.js
                │   ├── vendor-55523fc1.css
                │   ├── vendor-ac6fcfdf.js
                │   ├── css/
                │   │   └── style.css
                │   └── imgs/
                ├── datareports/
                │   └── assets/
                │       └── imgs/
                └── dataupload/
                    └── assets/
                        └── imgs/
```

---

# FHIR AWS Infrastructure – Terraform IaC

This repository provisions a complete FHIR system architecture using Terraform modules for serverless and supporting AWS resources.

## 📁 Directory Structure
```bash
.
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
└── modules
    ├── networking
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── storage
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── iam
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── lambda
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── api_gateway
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── cloudfront
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── rds
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── ec2
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── cognito
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
        
```

## 🧩 Components Overview

### 🦓 Zookeeper

- **Purpose:** Manages cluster coordination.
- **app.yml:** Defines a standalone Zookeeper pod, service, and configmap.

### 🌀 Apache NiFi

- **03-statefulset.yml (StatefulSet):** Core of the NiFi cluster.
- **initContainers:** Wait for Zookeeper readiness.
- **Environment Variables:** Controls networking, keystore/truststore, clustering.
- **Volume Mounts:** Stores data and scripts.
- **Probes:** Liveness and readiness checks.

### 🔐 TLS with Certs

- **security.sh (from `configmap-ssl.yml`):** Sets up private key, CSR, signs with CA, configures keystores.
- **ca.yaml:** Secret storing CA key and cert.

### ⚖️ HorizontalPodAutoscaler

- **05-autoscale.yml:** Scales NiFi pods based on CPU/memory utilization.

### 🌐 Services

- **04-network.yml:** Headless service for intra-cluster DNS.
- **06-publish.yml:** LoadBalancer to expose NiFi UI.

---

## 🛠 Deployment Steps

### Apply terraform

```bash
terraform apply
```

---



# 🧾 Access Instructions for EC2 and RDS (FHIR Project)

This document provides detailed steps to access the EC2 instance and the RDS database created using Terraform.

---

## 🔐 1. Key Pair Setup

Your EC2 instance uses the key pair defined in the following Terraform block:

```hcl
resource "aws_key_pair" "hapi" {
  key_name   = "${var.environment}-kp-hapi"
  public_key = file("${path.module}/vofox.pub")
}
```

- **Public key location**: `modules/ec2/vofox.pub`
- **Private key file** (needed for SSH): `modules/ec2/vofox`

Ensure the private key is securely stored and access is restricted.

---

## 🖥️ 2. Accessing the EC2 Instance

The EC2 instance is used for running the HAPI FHIR server and also connecting to the RDS database.

### 🔧 Prerequisites

- Ensure you have the private key file: `vofox`


### ✅ SSH Access Command

```bash
ssh -i ./modules/ec2/vofox ubuntu@<EC2_PUBLIC_IP>
```

> Replace `<EC2_PUBLIC_IP>` with the actual public IP of your EC2 instance.

---

## 🛡️ 3. Security Groups

### EC2 Security Group Rules

| Rule | Protocol | Port | Source    |
|------|----------|------|-----------|
| SSH  | TCP      | 22   | 0.0.0.0/0 |
| HTTP | TCP      | 8080 | 0.0.0.0/0 |
| Egress | ALL | ALL | 0.0.0.0/0 |

> ⚠️ **Important**: In production, restrict `cidr_blocks` to your IP range.

### RDS Security Group Rules

| Rule | Protocol | Port | Source (SG) |
|------|----------|------|-------------|
| PostgreSQL | TCP | 5432 | EC2 SG (`aws_security_group.ec2_sg.id`) |
| Egress | ALL | ALL | 0.0.0.0/0 |

---

## 🛠️ 3. Configure pgAdmin with SSH Tunnel

Use pgAdmin to connect to RDS through EC2 using SSH tunneling.

### 🧱 Required Details

- EC2 Public IP
- EC2 Username: `ubuntu`
- RDS Endpoint
- DB Name, Username, and Password
- RSA Key File: `vofox`

### 📌 Steps in pgAdmin

1. Open **pgAdmin**
2. Click **"Create" > "Server…"**
3. In the **General** tab:
   - **Name**: `RDS via EC2 Tunnel`
4. Go to the **Connection** tab:
   - **Host name/address**: `localhost`
   - **Port**: `5432`
   - **Maintenance database**: `<your-db-name>`
   - **Username**: `<your-db-username>`
   - **Password**: `<your-db-password>`
5. Go to the **SSH Tunnel** tab:
   - ✅ Use SSH tunneling: **Checked**
   - **Tunnel host**: `<EC2_PUBLIC_IP>`
   - **Username**: `ubuntu`
   - **Authentication method**: `Identity file`
   - **Identity file**: Select `vofox`
   - **Tunnel port**: `22`
   - **Local bind address**: `127.0.0.1`
   - **Local bind port**: `5432`
6. Click **Save**

---
## Update the S3 UI

### modify the values first 

$NewRegion        = ""
$NewUserPoolId    = ""
$NewClientId      = ""
$NewApiBaseUrl    = ""
$NewCDNBaseUrl    = ""

```bash
powershell -ExecutionPolicy Bypass -File .\modules\storage\replace_aws_values.ps1
```
---

## Destroy Infra

### Delete Loadbalancer First

```bash
powershell -ExecutionPolicy Bypass -File .\destroy.ps1
```

### IaC Destroy

```bash
terraform destroy
```
---
