#!/bin/bash
#129MiB as buffer between partitions
function wipe_hdd{ #argument is the hdd partition to wipe
	# 2 - wipe your existing disk with random data
	# Wiping your disk is an optional step. This is supposed to make your data harder to eventually recover via cryptoanalysis.
	# If you're not worried about this, and just want to make sure that whoever steals your notebook doesn't look into your 
	# cat pictures, then feel free to skip to Partitioning below.
	# Relevant XKCD: https://xkcd.com/538/
	# wipe the SSD with randomness
	echo "cryptsetup open --type plain " +$1 + "container"
	echo "dd if=/dev/zero of=/dev/mapper/container"
	echo "#this will take a while"
	echo "cryptsetup luksClose container"
}
function setup_swap_encrypted{

}
function setup_swap_unencrypted{

}
function setup_luks_container { #argument is partition
	
	echo "cryptsetup --cipher aes-xts-plain64 --hash sha512 --use-random --verify-passphrase luksFormat " +$1
	
}
	 

function format_usb { #Argument is the USB device
	local USB = $1
	sgdisk --new=1:0:+1MiB --type-code=1:ef02 --change-name=1:"BIOS" $USB 
	sgdisk --new=2:+129:+1024MiB --type-code=2:8300 --change-name=2:"Boot" $USB #/boot
	sgdisk --new=3:+129:+300MiB --type-code=3:ef00 --change-name=3:"EFI" $USB #/boot/efi
	}
	
function format_hdd_boot { #First Argument is the HDD device Second Argument is whether it will be a windows dual boot TRUE
	local HDD = $1
	sgxdisk --new=1:0:+1MiB --type-code=1:ef02 --change-name=1:"BIOS" $HDD 
	sgdisk --new=2:+129:+500MiB --type-code=2:8300 --change-name=2:"Boot" $HDD #/boot
	sgdisk --new=3:+129:+300MiB --type-code=3:ef00 --change-name=3:"EFI" $HDD #/boot/efi
	if $2 == TRUE;then sgdisk --new=4:+129:+129MiB --type-code=4:0c01 --change-name=4:"Microsoft"$HDD ;fi 
	}
	
function format_hdd_main { #Argument is the HDD device and if presented the size for the OS partition
	local HDD = $1

	if [[ $# -eq 2 ]] ; then  local SIZE = $2;else local SIZE = -129MiB;fi # check if size parameter was given else use everything
#	ENDSECTOR='sgdisk -E $HDD'
#	FIRSTSECTOR='sgdisk -F $HDD'
	sgdisk --new=5:+129:+4GiB --type-code=5:8200 --change-name=5:"Swap" $HDD
	sgdisk --new=6:+129:$SIZE --type-code=6:8300 --change-name=6:"OS" $HDD
 }
 
function setup_fs{

}

while true; do
	read -p "Which setupmode would you like to run? 
	(encrypthdd|encryptusb|unencrypted|dualboot)" setupmode
	case $setupmode in
		"encrypthdd")
			read -p "Which device is your HDD? (/dev/sdX)" HDD
			format_hdd $HDD
			format_hdd_main $HDD
			echo "run"
			#echo command to encrypt and mount fs
			wipe_hdd $HDD
			break
			;;		
		"encryptusb")
			read -p "Which device is your USB? (/dev/sdY)" USB
			format_usb $USB
			read -p "Which device is your HDD? (/dev/sdX)" HDD
			format_hdd_main $HDD
			echo "run"
			#echo command to encrypt and mount fs
			wipe_hdd $HDD
			break
			;;
		"unencrypted")
			read -p "Which device is your HDD? (/dev/sdX)" HDD
			format_hdd $HDD
			format_hdd_main $HDD
			#mkfs
			#mountfs as expected
		"prepared")	# it does not matter if encrypted or not as the partition layout will not change 
			
			;;
		
	esac
#now we will generate the btrfs and mount points


