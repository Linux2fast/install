#!/bin/bash

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
