# array-scripts
Random collection of scripts to make working with various drive arrays easier. 

https://techsmix.net/debian-stretch-btrfs/ outlines the setup process of an array where these scripts are useful. 

## Requirements:
1. `N` drives, each encrypted with LUKS keyfiles which are themselves encrypted and signed with a GPG key
2. Lots of tinfoil. 
 
## `array-key-rotate.sh`
- Useful if you have X number of LUKS key files and need to rotate them for any reason. 

## `array-unlock.sh`
- Matches based on LuksUUID of drives looking up keys and attempting to decrypt with GPG 


### Encrypting a new drive:

```
openssl rand -base64 2048 | gpg -q  --trust-model always --encrypt --sign --armor -r $ENCRYPTION_SUB_KEY_ID > ./luks-dev-sdX.key
gpg -d ./luks-dev-sdX.key 2>/dev/null | cryptsetup -v --key-file=- --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-urandom luksFormat /dev/sdX
```
Ensure to update the backup tarball with the new key

