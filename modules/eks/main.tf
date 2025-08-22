resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.eks_version
  role_arn = aws_iam_role.cluster.arn

  access_config {
    authentication_mode                         = var.authentication_mode
  }

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = var.cluster_endpoint_public_access
    endpoint_private_access = var.cluster_endpoint_private_access
  }

  tags = var.tags
}

# Cluster IAM Role
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# Node IAM Role
resource "aws_iam_role" "nodes" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

# Node Group
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.eks_node_desired_size
    max_size     = var.eks_node_max_size
    min_size     = var.eks_node_min_size
  }

  ami_type       = var.eks_node_ami_type
  instance_types = var.eks_node_instance_types
  capacity_type  = var.eks_node_capacity_type

  tags = var.tags
}

# OIDC Provider
resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0ecdac11d"]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# EBS CSI Driver IAM Role
resource "aws_iam_role" "ebs_csi_driver" {
  name = "AmazonEKS_EBS_CSI_DriverRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.this.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${aws_iam_openid_connect_provider.this.url}:aud" = "sts.amazonaws.com",
            "${aws_iam_openid_connect_provider.this.url}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_policy_attach" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.this.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.ebs_csi_addon_version
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.this,
    aws_iam_role.ebs_csi_driver
  ]
}

# Cluster Access
resource "aws_eks_access_entry" "devops_user" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.devops_user_arn
  depends_on = [aws_eks_cluster.this]
}

resource "aws_eks_access_policy_association" "devops_admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.devops_user_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_entry" "root_account" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.root_account_arn
}

resource "aws_eks_access_policy_association" "root_admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.root_account_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# Configure EKS and NiFi
resource "null_resource" "configure_eks_and_nifi" {
  depends_on = [aws_eks_addon.ebs_csi_driver]

  triggers = {
    config_hash = filesha256("${path.module}/deployment/nifi/01-configmap.yml")
    certs_hash  = filesha256("${path.module}/certs/ca-cert.pem")
    certs_hash  = filesha256("${path.module}/certs/ca-key.pem")
  }

  provisioner "local-exec" {
    command = <<EOT
      # Enable strict error handling
      $ErrorActionPreference = 'Stop'
      
      # Configure kubectl
      aws eks --region ${var.aws_region} update-kubeconfig --name ${var.cluster_name}
      
      # Create TLS secret (idempotent)
      kubectl create secret generic nifi-ca-secret `
        --from-file=ca.crt=${path.module}/certs/ca-cert.pem `
        --from-file=ca.key=${path.module}/certs/ca-key.pem `
        --dry-run=client -o yaml | kubectl apply -f -

      kubectl apply -f "${path.module}/deployment/nifi/06-publish.yml"

      $retryCount = 0
      $maxRetries = 5
      $sleepSeconds = 10
      
      do {
        Start-Sleep -Seconds $sleepSeconds
        $LB_DNS = (kubectl get svc nifi-0 -o json | ConvertFrom-Json).status.loadBalancer.ingress[0].hostname
        $retryCount++
      } while ((-not $LB_DNS) -and ($retryCount -lt $maxRetries))
      
      if (-not $LB_DNS) {
        Write-Error "Timed out waiting for load balancer DNS"
        exit 1
      }

      # Update configmap with LB hostname
      $configPath = "${path.module}/deployment/nifi/01-configmap.yml"
      (Get-Content $configPath) -replace 'NIFI_WEB_PROXY_HOST:.*', "NIFI_WEB_PROXY_HOST: `"$LB_DNS`"" | Set-Content $configPath

      # Apply full configuration
      kubectl apply -k ${path.module}/deployment
      
    EOT

    interpreter = ["powershell", "-Command"]
  }
}
resource "null_resource" "add_gitlab_registry" {

   depends_on = [
   null_resource.configure_eks_and_nifi
  ]

  provisioner "local-exec" {
    command = "powershell.exe -ExecutionPolicy Bypass -File ./modules/eks/add-registry.ps1"

    environment = {
      GITLAB_PAT = var.gitlab_pat
    }
  }

  triggers = {
    gitlab_token_hash = sha256(var.gitlab_pat)
  }
}



