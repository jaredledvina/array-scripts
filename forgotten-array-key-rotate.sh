#!/bin/bash 
# Attempts to fetch in-memory master key file for a device and if successful
# will use that to insert a newly generated master key. Useful if the current
# keyfile for a device was lost but, the device is still open on the system.

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
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

echo -n New GPG Passphrase: 
read -s GPGPW

echo ''

echo -n GPG Key ID: 
read GPGKEYID

if [ -z $DEVICE ]; then
    echo "-d|--device not set, bailing..."
    exit 1
elif [ "$DEVICE" == 'all' ]; then
	DEVICES=$(blkid -t TYPE=crypto_LUKS -o device)
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
        openssl rand -base64 2048 | gpg -q --passphrase $GPGPW --trust-model always --encrypt --sign --armor -r $GPGKEYID > $NEWKEYFILE 2>/dev/null
        MASTERKEY=$(dmsetup table luks_$( echo $DEVICE | awk -F/ '{ print $3 }' ) --showkeys | awk '{print$5}' 2>/dev/null)
        if [ -z "$MASTERKEY" ]
        then
            echo "Unable to retrieve in-memory master key for $DEVICE, skipping rotate..."
        else
            echo "Adding new key for device $DEVICE"
            mkfifo /tmp/newkey-$DEVICEUUID
            NEWKEY=$(gpg -q --passphrase $GPGPW -d $NEWKEYFILE 2>/dev/null)
            gpg -q --passphrase $GPGPW -d $NEWKEYFILE 2>/dev/null > /tmp/newkey-$DEVICEUUID &
            cryptsetup luksAddKey --master-key-file <(dmsetup table luks_$( echo $DEVICE | awk -F/ '{ print $3 }' ) --showkeys | awk '{print$5}' | xxd -r -p1) --key-file=- $DEVICE /tmp/newkey-$DEVICEUUID
            if [ $? -ne 0 ]; then
                echo "Failed to add new key to $DEVICE, bailing..."
                rm -f /tmp/newkey-$DEVICEUUID
                exit 1
            fi
            rm -f /tmp/newkey-$DEVICEUUID
            echo "Testing new keyfile works"
            gpg -q --passphrase $GPGPW -d $NEWKEYFILE 2>/dev/null | cryptsetup luksOpen --key-file=- $DEVICE --test-passphrase
            if [ $? -eq 0 ]
            then
                echo "New keyfile works!"
                echo "You must manually remove the old keys for $DEVICE"
            else
                echo "New keyfile failed."
            fi
        fi
    fi
done
