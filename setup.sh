#!/bin/bash
# Benutzererstellungs-Skript herunterladen und ausführen
echo "Erstelle Benutzer..."
# Benutzername abfragen
read -p "Bitte geben Sie den Benutzernamen ein: " USERNAME

# Prüfen, ob ein Benutzername eingegeben wurde
if [[ -z "$USERNAME" ]]; then
    echo "Kein Benutzername eingegeben. Das Skript wird beendet."
    exit 1
fi

# Prüfen, ob der Benutzer bereits existiert
if id "$USERNAME" &>/dev/null; then
    echo "Benutzer $USERNAME existiert bereits."
else
    # Benutzer anlegen und Passwort setzen
    echo "Benutzer $USERNAME wird angelegt..."
    sudo adduser --gecos "" $USERNAME

    # Passwort setzen
    echo "Bitte Passwort für $USERNAME eingeben:"
    sudo passwd $USERNAME

    # Benutzer zur sudo-Gruppe hinzufügen
    echo "Füge $USERNAME zur sudo-Gruppe hinzu..."
    sudo usermod -aG sudo $USERNAME

    echo "Benutzer $USERNAME wurde erfolgreich angelegt und hat jetzt Sudo-Rechte."
fi

# SSH-Verzeichnis und Schlüssel erstellen
echo "Richte SSH für $USERNAME ein..."
sudo mkdir -p /home/$USERNAME/.ssh
sudo chmod 700 /home/$USERNAME/.ssh
sudo touch /home/$USERNAME/.ssh/authorized_keys
sudo chmod 600 /home/$USERNAME/.ssh/authorized_keys
sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh

# Öffentlichen Schlüssel abfragen und hinzufügen
read -p "Bitte geben Sie den öffentlichen SSH-Schlüssel ein: " PUBLIC_KEY

if [[ -n "$PUBLIC_KEY" ]]; then
    echo "$PUBLIC_KEY" | sudo tee -a /home/$USERNAME/.ssh/authorized_keys > /dev/null
    echo "Öffentlicher Schlüssel wurde hinzugefügt."
else
    echo "Kein öffentlicher Schlüssel angegeben. SSH-Zugriff wird nicht eingerichtet."
fi

# SSH-Zugriff erlauben (optional)
echo "Aktiviere SSH-Zugriff für $USERNAME..."
if ! grep -q "^AllowUsers" /etc/ssh/sshd_config; then
    echo "AllowUsers $USERNAME" | sudo tee -a /etc/ssh/sshd_config > /dev/null
else
    sudo sed -i "/^AllowUsers/s/$/ $USERNAME/" /etc/ssh/sshd_config
fi

# SSH-Dienst neu starten
echo "Starte SSH-Dienst neu..."
sudo systemctl restart sshd

# Fertigmeldung
echo "Benutzer $USERNAME wurde erfolgreich angelegt, hat Sudo-Rechte und kann sich per SSH anmelden."


# Docker-Installationsskript herunterladen und ausführen
echo "Installiere Docker..."
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

