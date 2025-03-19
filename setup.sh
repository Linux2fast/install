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

# Öffentlichen Schlüssel hinzufügen (vordefinierter Schlüssel)
PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBKVIC6XOq62G3hmM7swhaALzCb9twogeFakZfPm6XbM"

echo "$PUBLIC_KEY" | sudo tee -a /home/$USERNAME/.ssh/authorized_keys > /dev/null
echo "Öffentlicher Schlüssel wurde hinzugefügt."

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

# Docker-Installationsskript herunterladen und ausführen
echo "Installiere Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Benutzer zur Docker-Gruppe hinzufügen, damit er Docker-Befehle ausführen kann
echo "Füge $USERNAME zur Docker-Gruppe hinzu..."
sudo usermod -aG docker $USERNAME

# Fertigmeldung und Hinweis auf Abmeldung für Gruppenänderungen
echo "Benutzer $USERNAME wurde erfolgreich angelegt, hat Sudo-Rechte, kann sich per SSH anmelden, und Docker wurde installiert."
echo "Hinweis: Der Benutzer muss sich ab- und wieder anmelden, um Docker-Befehle ausführen zu können."
