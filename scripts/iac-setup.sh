#!/bin/bash
# iac-setup.sh — Infrastructure as Code: provision local production environment

set -e

echo "Starting Infrastructure Provisioning..."

if ! command -v node &> /dev/null; then
  echo "Node.js not found. Please install Node.js from https://nodejs.org/"
  exit 1
fi

if ! command -v pm2 &> /dev/null; then
  echo "Installing PM2 process manager..."
  npm install -g pm2
else
  echo "PM2 already installed."
fi

PRODUCTION_ROOT="$HOME/local-production"

echo "Creating deployment directories..."
mkdir -p "$PRODUCTION_ROOT/blue"
mkdir -p "$PRODUCTION_ROOT/green"
mkdir -p "$PRODUCTION_ROOT/router"

if [ ! -f "$PRODUCTION_ROOT/active_env.txt" ]; then
  touch "$PRODUCTION_ROOT/active_env.txt"
fi

echo "Environment Provisioned Successfully!"
echo "Directories created in: $PRODUCTION_ROOT/"
