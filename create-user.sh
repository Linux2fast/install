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
sudo chown $USERNAME:$USERNAME /home/$USERNAME/.ssh

# SSH-Zugriff erlauben
echo "Aktiviere SSH-Zugriff für $USERNAME..."
if ! grep -q "^AllowUsers" /etc/ssh/sshd_config; then
    echo "AllowUsers $USERNAME" | sudo tee -a /etc/ssh/sshd_config
else
    sudo sed -i "/^AllowUsers/s/$/ $USERNAME/" /etc/ssh/sshd_config
fi

# SSH-Dienst neu starten
echo "Starte SSH-Dienst neu..."
sudo systemctl restart sshd

# Fertig
echo "Benutzer $USERNAME wurde erfolgreich angelegt, hat Sudo-Rechte und kann sich per SSH anmelden."
