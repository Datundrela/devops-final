# setup.ps1 — Windows environment preparation (PowerShell)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Set-Location $ProjectRoot

Write-Host "=========================================="
Write-Host " DevOps Final — Environment Setup (Windows)"
Write-Host "=========================================="

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Error "Node.js is required. Install from https://nodejs.org/"
}

Write-Host "[1/4] Installing npm dependencies..."
npm install

if (-not (Test-Path ".env")) {
    Write-Host "[2/4] Creating .env from .env.example..."
    Copy-Item ".env.example" ".env"
} else {
    Write-Host "[2/4] .env already exists — skipping"
}

Write-Host "[3/4] Creating local production directories..."
$prodRoot = Join-Path $env:USERPROFILE "local-production"
@("blue", "green", "router") | ForEach-Object {
    New-Item -ItemType Directory -Force -Path (Join-Path $prodRoot $_) | Out-Null
}
if (-not (Test-Path (Join-Path $prodRoot "active_env.txt"))) {
    "" | Out-File (Join-Path $prodRoot "active_env.txt") -Encoding utf8
}

Write-Host "[4/4] Running tests to validate environment..."
npm test

Write-Host ""
Write-Host "Environment ready."
Write-Host "  npm start        — run app locally"
Write-Host "  npm run deploy   — deploy via Git Bash (deploy.sh uses PM2)"
