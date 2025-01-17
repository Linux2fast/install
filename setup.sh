#!/bin/bash

# Docker-Installationsskript herunterladen und ausführen
echo "Installiere Docker..."
bash <(curl -s https://raw.githubusercontent.com/<IhrGitHubBenutzername>/<IhrRepositoryName>/main/docker-install.sh)

# Benutzererstellungs-Skript herunterladen und ausführen
echo "Erstelle Benutzer..."
bash <(curl -s https://raw.githubusercontent.com/<IhrGitHubBenutzername>/<IhrRepositoryName>/main/create-user.sh)
