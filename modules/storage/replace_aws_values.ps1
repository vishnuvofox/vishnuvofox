$NewRegion        = "us-east-1"
$NewUserPoolId    = "us-east-1_4uJHTG8fv" 
$NewClientId      = "31u538536k8eruqnfpa5jjd8s1" 
$NewApiBaseUrl    = "https://ym7vjm6ifh.execute-api.us-east-1.amazonaws.com/Prod/" 
$NewCDNBaseUrl    = "https://d16z7gqt7aou1s.cloudfront.net" 

$FilePath = "modules\storage\fhir-ui\assets\index-1e6c6213.js"

if (-not (Test-Path $FilePath)) {
    Write-Error "The file '$FilePath' does not exist."
    exit 1
}

# Create backup
$backupPath = "$FilePath.bak"
Copy-Item -Path $FilePath -Destination $backupPath -Force
Write-Host "Created backup of original file at '$backupPath'"

# Read content
$originalContent = Get-Content -Path $FilePath -Raw -Encoding UTF8
$content = $originalContent

# Replace region/userPoolId/webClientId block
$content = $content -replace '\{region:"[^"]+",userPoolId:"[^"]+",userPoolWebClientId:"[^"]+"\}', `
    "{region:`"$NewRegion`",userPoolId:`"$NewUserPoolId`",userPoolWebClientId:`"$NewClientId`"}"

# Replace baseURL
$content = $content -replace '\{baseURL:"[^"]+"\}', `
    "{baseURL:`"$NewApiBaseUrl`"}"

# Replace he=CloudFront link with query params
$content = $content -replace 'he=https://[^/]+\.cloudfront\.net/\?blocklyId=\$\{ee\}&templateId=\$\{x\}&currentVersion=\$\{l\}&tenantName=\$\{fe\}&token=\$\{u\}', `
    "he=$NewCDNBaseUrl`?blocklyId=\${ee}&templateId=\${x}&currentVersion=\${l}&tenantName=\${fe}&token=\${u}"

# Replace ,V="CloudFront URL"
$content = $content -replace ',V="https://[^/]+\.cloudfront\.net/"', `
    ",V=`"$NewCDNBaseUrl`""

# Save updated content
try {
    Set-Content -Path $FilePath -Value $content -Encoding UTF8 -Force
    Write-Host "Successfully updated '$FilePath'"
} catch {
    Write-Error "Failed to write to '$FilePath': $_"
    exit 1
}

# Verify
Write-Host "Verifying changes..."
$changesMade = $false

if ($originalContent -ne $content) {
    Write-Host "Changes applied:"
    Write-Host " - Region/UserPool/WebClient updated to: $NewRegion / $NewUserPoolId / $NewClientId"
    Write-Host " - Base URL updated to: $NewApiBaseUrl"
    Write-Host " - CloudFront URLs updated to: $NewCDNBaseUrl"
    $changesMade = $true
} else {
    Write-Host "No changes were made. Skipping Terraform."
    exit 0
}

# Remove Terraform state
Write-Host "Removing Terraform state for 'module.storage.null_resource.upload_ui_files'..."
terraform.exe state rm "module.storage.null_resource.upload_ui_files"

# Reapply Terraform
Write-Host "Reapplying Terraform to upload new UI files..."
terraform apply --target=module.storage.null_resource.upload_ui_files --auto-approve
