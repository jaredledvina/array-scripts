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
