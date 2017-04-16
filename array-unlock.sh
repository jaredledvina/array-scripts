#!/bin/bash
# Automatically unlocks all LUKS encrypted devices with keyfiles matched by UUID

DEVICES=$(lsblk -dlnp --output NAME)

echo -n "Path to GPG encrypted LUKS keyfiles: "
read GPGKEYDIR

echo -n "GPG Passphrase: "
read -s GPGPW
echo ""

if [ ! -d $GPGKEYDIR ]; then
    echo "$GPGKEYDIR is not a directory, bailing..."
    exit 1
fi

for DEVICE in $DEVICES; do
    DEVICEUUID=$(cryptsetup luksUUID $DEVICE)
    if [ $? -ne 0 ]; then
        echo "Device $DEVICE is not a LUKS device, skipping..."
    else
        echo "Searching for keyfile matching UUID $DEVICEUUID in $GPGKEYDIR"
        DEVICEKEYFILE=$(find $GPGKEYDIR -type f -iname *$DEVICEUUID*)
        if [ -n "$DEVICEKEYFILE" ]; then
            echo "Attempting to unlock $DEVICE - $DEVICEUUID with $DEVICEKEYFILE"
            DEVICELETTER=$(blkid | grep $DEVICEUUID | awk '{ print $1 }' | sed -e 's/^.*\(.\).$/\1/')
            if [ $? -ne 0 ]; then
                echo "Unable to grab drive letter for $DEVICE with $DEVICEUUID, skipping..."
            else
                gpg -q --passphrase "$GPGPW" -d "$DEVICEKEYFILE" 2>/dev/null | cryptsetup luksOpen --key-file=- $DEVICE luks_sd$DEVICELETTER 
                if [ $? -eq 0 ]; then
                    echo "Successfully unlocked $DEVICE - $DEVICEUUID with $DEVICEKEYFILE"
                else
                    echo "Failed to unlock $DEVICE - $DEVICEUUID with $DEVICEKEYFILE"
                fi
            fi
        else
            echo "Unable to locate keyfile for drive $DEVICE with UUID $DEVICEUUID in $GPGKEYDIR, skipping..."
        fi
    fi
done
