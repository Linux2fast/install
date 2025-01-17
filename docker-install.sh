#!/bin/bash

# Dieses Skript installiert Docker und Docker Compose in einem unprivilegierten LXC-Container.

# 1. System aktualisieren und notwendige Pakete installieren
echo "System wird aktualisiert und notwendige Pakete werden installiert..."
sudo apt-get update && sudo apt-get upgrade -y

# Installieren von grundlegenden Paketen
echo "Installiere grundlegende Pakete..."
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

# Überprüfen und Installieren von `fuse-overlayfs`
if ! dpkg -l | grep -qw fuse-overlayfs; then
    echo "Installiere fuse-overlayfs..."
    sudo apt-get install -y fuse-overlayfs
else
    echo "fuse-overlayfs ist bereits installiert."
fi

# 2. Docker GPG-Schlüssel hinzufügen
echo "Docker GPG-Schlüssel wird hinzugefügt..."
sudo mkdir -p /etc/apt/keyrings
if curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg; then
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
else
    echo "Fehler beim Herunterladen des Docker GPG-Schlüssels!"
    exit 1
fi

# 3. Docker-Repository hinzufügen
echo "Docker-Repository wird hinzugefügt..."
if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
else
    echo "Docker-Repository ist bereits vorhanden."
fi

# 4. Paketquellen aktualisieren und Docker installieren
echo "Paketquellen werden aktualisiert..."
sudo apt-get update

echo "Docker wird installiert..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 5. Konfiguration für unprivilegierten Betrieb anpassen (fuse-overlayfs)
echo "Konfiguration für unprivilegierten Betrieb wird angepasst..."
cat <<EOF | sudo tee /etc/docker/daemon.json > /dev/null
{
    "storage-driver": "fuse-overlayfs"
}
EOF

# Sicherstellen, dass das Docker-Verzeichnis existiert und korrekt eingerichtet ist
if [ ! -d "/var/lib/docker" ]; then
    echo "Docker-Verzeichnis wird erstellt..."
    sudo mkdir -p /var/lib/docker
    sudo chown $(id -u):$(id -g) /var/lib/docker
fi

# 6. Docker-Dienst starten und aktivieren
echo "Docker-Dienst wird gestartet..."
sudo systemctl enable docker --now || {
    echo "Fehler beim Starten des Docker-Dienstes!"
    exit 1
}

# 7. Installation überprüfen
echo "Installation überprüfen..."
if docker run hello-world; then
    echo "Docker wurde erfolgreich installiert und getestet!"
else
    echo "Fehler bei der Ausführung von 'docker run hello-world'. Bitte prüfen Sie die Installation."
fi

echo "Installation abgeschlossen!"
