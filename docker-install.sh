#!/bin/bash

# Dieses Skript installiert Docker und Docker Compose in einem unprivilegierten LXC-Container.

# 1. System aktualisieren
echo "System wird aktualisiert..."
sudo apt-get update && sudo apt-get upgrade -y

# 2. Notwendige Pakete installieren
echo "Notwendige Pakete werden installiert..."
sudo apt-get install -y ca-certificates curl gnupg lsb-release fuse-overlayfs

# 3. Docker GPG-Schlüssel hinzufügen
echo "Docker GPG-Schlüssel wird hinzugefügt..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 4. Docker-Repository hinzufügen
echo "Docker-Repository wird hinzugefügt..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. Paketquellen aktualisieren und Docker installieren
echo "Docker wird installiert..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 6. Konfiguration für unprivilegierten Betrieb anpassen
echo "Konfiguration für unprivilegierten Betrieb wird angepasst..."

# FUSE OverlayFS als Storage-Treiber festlegen
cat <<EOF | sudo tee /etc/docker/daemon.json
{
    "storage-driver": "fuse-overlayfs"
}
EOF

# Host-Dateisystem für Docker bereitstellen (falls erforderlich)
if [ ! -d "/var/lib/docker" ]; then
    echo "Docker-Verzeichnis wird erstellt..."
    mkdir -p /var/lib/docker
    sudo chown $(id -u):$(id -g) /var/lib/docker
fi

# 7. Docker-Dienst starten und aktivieren
echo "Docker-Dienst wird gestartet..."
sudo systemctl enable docker
sudo systemctl restart docker

# 8. Installation überprüfen
echo "Installation überprüfen..."
docker run hello-world || echo "Stellen Sie sicher, dass Docker korrekt funktioniert."

echo "Installation abgeschlossen!"
