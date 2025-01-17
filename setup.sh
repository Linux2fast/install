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
PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQChGl+ssfV7KGhsWe5mwA06XaNN8MznJv9DBKCUDnEqoVzyQ9ZrzRAArtUUYbTnjdptLVW1hA+7vhTWv4/qjFBJ8n/I/CMzkPBdJgq09LtaiDQDS4oYPKiz0X6ew7MOMDoZM0YQuLz+XHr53j1dAcwakx2XAK0FuSJ8EjXfbFfla26heFa1MJyCm96onZfu3eKQONsOpegDggi32UKfSgJ9SmA4ns79UydVqngFf595PsDmxbu1ef3Qs9saRGl28+mwLR1/Aki4wCcX9gwEbpM41fLtNNOa2Hg7CL7X3rSAFrj5i2h1YWOAkydjUaNHDZOk96k1JlLwxYeowJ8LYn6P4OULOvmk2Kt+9j98cXRxWVhbHHicppi8NWw3IEFqkQoVak9+gFhGRmugYBp6oBSXfPZQZnLshbGdx6nWk4u25x2v9EIoEMdbJjdBR3QmBWFu5BQfLZYpl4ppmdAzfPoutTIJhG6vWs0CpN5diGWAOSwQgdlZ7kv8Ji26XAKGUH2SdPozaHZFdaO/Am3C4k/BGvMnTUvb8ysa+LFCXGrbmNISUPETMTFUiAe1UT02/i8EdYCxFUDUsMhQeOyNuyGbr5o64gFP0KRLfTE/7SLf0fK2PjEi40DGbtTSFQgm0o5bJqJQt1R2cJ5trDoLrggvvKRPog4DKs1JjpIuR+DvHQ== nginx@nginx-Proxy-Manager"

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

# Fertigmeldung
echo "Benutzer $USERNAME wurde erfolgreich angelegt, hat Sudo-Rechte, kann sich per SSH anmelden, und Docker wurde installiert."
