param()

$ErrorActionPreference = "Stop"

# Path to the NiFi config YAML
$configPath = "$PSScriptRoot\deployment\nifi\01-configmap.yml"

# === Extract Host, Username, and Password from ConfigMap ===
$nifiHost = Select-String -Path $configPath -Pattern 'NIFI_WEB_PROXY_HOST:\s*(.+)' |
  ForEach-Object { $_.Matches[0].Groups[1].Value.Trim('" ').Replace("`r", "").Replace("`n", "") }

$nifiUsername = Select-String -Path $configPath -Pattern 'SINGLE_USER_CREDENTIALS_USERNAME:\s*(.+)' |
                  ForEach-Object { $_.Matches[0].Groups[1].Value.Trim('" ') }

$nifiPassword = Select-String -Path $configPath -Pattern 'SINGLE_USER_CREDENTIALS_PASSWORD:\s*(.+)' |
                  ForEach-Object { $_.Matches[0].Groups[1].Value.Trim('" ') }

$rawPort         = Select-String -Path $configPath -Pattern 'NIFI_WEB_HTTPS_PORT:\s*(.+)' |
                  ForEach-Object { $_.Matches[0].Groups[1].Value.Trim('" ') }

$port = ":$rawPort"

if (-not $nifiHost -or -not $nifiUsername -or -not $nifiPassword) {
  Write-Error "Failed to extract credentials or proxy host from $configPath"
  exit 1
}

Write-Host "Host: $nifiHost"
Write-Host "Username: $nifiUsername"
Write-Host "Password: $nifiPassword"
Write-Host "$port"

# === Get GitLab PAT from environment ===
$gitlabPat = "glft-QHvtzWzjTsBz4bxp8zfd" #$env:GITLAB_PAT
if (-not $gitlabPat) {
  Write-Error "GITLAB_PAT environment variable not set"
  exit 1
}

# Bypass SSL cert errors (self-signed cert workaround)
Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
  public bool CheckValidationResult(
    ServicePoint srvPoint, X509Certificate certificate,
    WebRequest request, int certificateProblem) {
    return true;
  }
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
Write-Host "Raw NIFI_WEB_PROXY_HOST value: '$nifiHost'"

# === Request Token from NiFi ===
Write-Host "Requesting NiFi access token..."

$baseUrl = "https://$nifiHost$port"

Write-Host "Computed baseUrl: $baseUrl"

# Wait for NiFi to be available
$healthUrl = "$baseUrl/nifi"
$maxAttempts = 30
$attempt = 0

Write-Host "Checking if NiFi is available at $healthUrl..."

while ($attempt -lt $maxAttempts) {
  try {
    $response = Invoke-WebRequest -Uri $healthUrl 
    if ($response.StatusCode -eq 200) {
      Write-Host "NiFi is up and running."
      break
    }
  } catch {
    Write-Host "NiFi not ready yet... attempt $($attempt + 1)/$maxAttempts"
  }
  Start-Sleep -Seconds 60
  $attempt++
}

if ($attempt -eq $maxAttempts) {
  Write-Error "NiFi did not start in time. Exiting script."
  exit 1
}



$token = Invoke-RestMethod `
  -Uri "$baseUrl/nifi-api/access/token" `
  -Method POST `
  -Body ("username={0}&password={1}" -f $nifiUsername, $nifiPassword) `
  -ContentType "application/x-www-form-urlencoded" `

# === Define GitLab Registry Body ===
$body = @{
  revision = @{ version = 0 }
  component = @{
    name = "GitLabRegistry"
    type = "org.apache.nifi.gitlab.GitLabFlowRegistryClient"
    uri  = "https://gitlab.com"
    description = "GitLab-backed NiFi Registry"
    authenticationStrategy = "ACCESS_TOKEN"
    properties = @{
      "GitLab API URL"       = "https://gitlab.com/"
      "GitLab API Version"   = "V4"
      "Repository Namespace" = "vofoxgit"
      "Repository Name"      = "NIFI"
      "Authentication Type"  = "ACCESS_TOKEN"
      "Access Token"         = $gitlabPat
      "Default Branch"       = "main"
      "Connect Timeout"      = "10 seconds"
      "Read Timeout"         = "10 seconds"
    }
  }
} | ConvertTo-Json -Depth 10 -Compress

# === Register GitLab Registry Client ===
Write-Host "Registering GitLab registry client in NiFi..."
Invoke-RestMethod `
  -Uri "$baseUrl/nifi-api/controller/registry-clients" `
  -Method POST `
  -Headers @{ Authorization = "Bearer $token" } `
  -Body $body `
  -ContentType "application/json" `

Write-Host "GitLab Registry Client registered successfully."
