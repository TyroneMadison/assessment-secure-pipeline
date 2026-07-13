#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"

Write-Host "=== STAGE 1: Checkout ===" -ForegroundColor Cyan
Write-Host "Using local working directory as source"

Write-Host "=== STAGE 2: Test ===" -ForegroundColor Cyan
py -m py_compile app/app.py
if ($LASTEXITCODE -ne 0) { throw "Syntax check failed" }
Write-Host "Syntax check passed"

Write-Host "=== STAGE 3: Build ===" -ForegroundColor Cyan
docker build -t localhost:5000/app:v1 ./app
if ($LASTEXITCODE -ne 0) { throw "Build failed" }

Write-Host "=== STAGE 4: Security Scan ===" -ForegroundColor Cyan
docker scout cves localhost:5000/app:v1 --exit-code --only-severity critical
if ($LASTEXITCODE -ne 0) {
    Write-Host "CRITICAL vulnerabilities found. Blocking push." -ForegroundColor Red
    throw "Security gate failed"
}
Write-Host "No critical CVEs found"

Write-Host "=== STAGE 5: Push ===" -ForegroundColor Cyan
docker push localhost:5000/app:v1
if ($LASTEXITCODE -ne 0) { throw "Push failed" }

Write-Host "=== STAGE 6: Deploy ===" -ForegroundColor Cyan
terraform apply -auto-approve
if ($LASTEXITCODE -ne 0) { throw "Deploy failed" }

Write-Host "=== STAGE 7: Verify ===" -ForegroundColor Cyan
Start-Sleep -Seconds 2
$response = curl.exe -s http://localhost:8082/health
Write-Host "Health check response: $response"
if ($response -notmatch "healthy") {
    Write-Host "Deploy verification failed, rolling back" -ForegroundColor Red
    docker run -d -p 8082:8080 --name app-rollback localhost:5000/app:v1
    throw "Rollback triggered"
}

Write-Host "=== PIPELINE COMPLETE ===" -ForegroundColor Green
