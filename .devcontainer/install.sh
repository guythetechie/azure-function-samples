#!/bin/bash

# Install Azure Functions Core Tools
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/debian/$(lsb_release -rs 2>/dev/null | cut -d'.' -f 1)/prod $(lsb_release -cs 2>/dev/null) main" > /etc/apt/sources.list.d/dotnetdev.list'
sudo apt-get update
sudo apt-get install azure-functions-core-tools

# Initialize Python
python3 -m venv "/workspaces/azure-function-samples/src/functionapp/.venv"
source "/workspaces/azure-function-samples/src/functionapp/.venv/bin/activate"
which python
python3 -m pip install -r "/workspaces/azure-function-samples/src/functionapp/requirements.txt"