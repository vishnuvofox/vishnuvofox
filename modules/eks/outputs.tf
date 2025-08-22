output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.this.arn
}

output "oidc_provider_url" {
  value = aws_iam_openid_connect_provider.this.url
}


output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "configure_eks_and_nifi_resource" {
  value = null_resource.configure_eks_and_nifi
}
