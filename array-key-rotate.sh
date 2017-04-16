#!/bin/bash 
# Rotates out LUKS key files encrypting them with a GPG Key ID

while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -d|--device)
    DEVICE="$2"
    shift # past argument
    ;;
    -k|--keydir)
    KEYDIR="$2"
    shift # past argument
    ;;
    -o|--oldkeydir)
    OLDKEYDIR="$2"
    shift # past argument
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

echo "The following passphrases might be the same depending on your setup"
echo -n Old GPG Passphrase:
read -s GPGPW

echo -n New GPG Passphrase:
read -s GPGPW2

echo -n GPG Key ID:
read GPGKEYID

if [ ! -d $OLDKEYDIR ]; then
    echo "$OLDKEYDIR is not a directory, bailing"
    exit 1
elif [ -z $OLDKEYDIR ]; then
    echo "-o|--oldkeydir not set, bailing..."
    exit 1
fi

if [ -z $DEVICE ]; then
    echo "-d|--device not set, bailing..."
    exit 1
elif [ "$DEVICE" == 'all' ]; then
	DEVICES=$(lsblk -dlnp --output NAME)
else
	if [ -b $DEVICE ]; then
		DEVICES=$DEVICE
	else
		echo "Device $DEVICE is not a block device, bailing..."
		exit 1
	fi
fi
if [ -z $KEYDIR ]; then
    echo "-k|--keydir not set, bailing..."
    exit 1
fi
if [ -z $GPGKEYID ]; then
    echo "You must enter a GPG Key ID"
    exit 1
fi

cd $HOME
mkdir -p $KEYDIR

for DEVICE in $DEVICES; do
    DEVICEUUID=$(cryptsetup luksUUID $DEVICE)
    if [ $? -ne 0 ] 
    then
        echo "Device $DEVICE is not a LUKS device, skipping..."
    else
        DRIVEUUID=$(cryptsetup luksUUID $DEVICE)
        echo "Generating new encryption key for $DEVICE - $DEVICEUUID"
        NEWKEYFILE="$KEYDIR/$DRIVEUUID.gpg"
        openssl rand -base64 2048 | gpg -q --passphrase $GPGPW2 --trust-model always --encrypt --sign --armor -r $GPGKEYID > $NEWKEYFILE 2>/dev/null
        OLDKEY=$(gpg --passphrase $GPGPW -q -d $(find $OLDKEYDIR -type f -iname *$DRIVEUUID*) 2>/dev/null)
        if [ -z "$OLDKEY" ]
        then
            echo "Unable to find old key for $DEVICE, skipping rotate..."
        else
            echo "Adding new key for device $DEVICE"
            mkfifo /tmp/newkey-$DEVICEUUID
            NEWKEY=$(gpg -q --passphrase $GPGPW2 -d $NEWKEYFILE 2>/dev/null)
            gpg -q --passphrase $GPGPW2 -d $NEWKEYFILE 2>/dev/null > /tmp/newkey-$DEVICEUUID &
            gpg --passphrase $GPGPW -q -d $(find $OLDKEYDIR -type f -iname *$DRIVEUUID*) 2>/dev/null | cryptsetup luksAddKey --key-file=- $DEVICE /tmp/newkey-$DEVICEUUID
            if [ $? -ne 0 ]; then
                echo "Failed to add new key to $DEVICE, bailing..."
                exit 1
            fi
            rm -f /tmp/newkey-$DEVICEUUID
            echo "Testing new keyfile works"
            gpg -q --passphrase $GPGPW2 -d $NEWKEYFILE 2>/dev/null | cryptsetup luksOpen --key-file=- $DEVICE --test-passphrase
            if [ $? -eq 0 ]
            then
                echo "New keyfile works!"
                echo "Removing old key for device $DEVICE"
                gpg --passphrase $GPGPW -q -d $(find $OLDKEYDIR -type f -iname *$DRIVEUUID*) 2>/dev/null | cryptsetup luksRemoveKey $DEVICE --key-file=-
            else
                echo "New keyfile failed. Not removing old keyfile"
            fi
        fi
    fi
done
