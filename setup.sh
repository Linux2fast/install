#!/bin/bash
# Benutzererstellungs-Skript herunterladen und ausführen
echo "Erstelle Benutzer..."
bash (curl -s https://raw.githubusercontent.com/Linux2fast/install/main/create-user.sh)
# Docker-Installationsskript herunterladen und ausführen
echo "Installiere Docker..."
bash (curl -s https://raw.githubusercontent.com/Linux2fast/install/main/docker-install.sh)

