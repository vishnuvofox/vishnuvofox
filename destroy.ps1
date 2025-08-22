Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Starting resource cleanup..." -ForegroundColor Cyan

# Delete specific Kubernetes resources
if (Test-Path .\modules\eks\deployment\nifi\06-publish.yml) {
    Write-Host "Deleting NiFi publish deployment..." -ForegroundColor Yellow
    kubectl delete -f .\modules\eks\deployment\nifi\06-publish.yml
} else {
    Write-Host "NiFi publish deployment file not found, skipping." -ForegroundColor DarkYellow
}

# Delete all Kubernetes resources in the deployment directory
if (Test-Path .\modules\eks\deployment\) {
    Write-Host "Deleting all Kubernetes resources in deployment directory..." -ForegroundColor Yellow
    kubectl delete -k .\modules\eks\deployment\
} else {
    Write-Host "Deployment directory not found, skipping Kubernetes delete." -ForegroundColor DarkYellow
}

# Destroy Terraform-managed infrastructure
if (Test-Path .\terraform.tfstate) {
    Write-Host "Destroying Terraform-managed infrastructure..." -ForegroundColor Yellow
    terraform destroy --auto-approve
} else {
    Write-Host "Terraform state file not found, skipping terraform destroy." -ForegroundColor DarkYellow
}

Write-Host "Cleanup complete." -ForegroundColor Green