#!/bin/bash
# 
function get_mirror_list{
#gets a new mirrorlist if original was destroyed
curl -o /etc/pacman.d/mirrorlist https://www.archlinux.org/mirrorlist/all/
}

function setup_mirror_list{
#setup mirrors
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup 
sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist.backup
rankmirrors -n 10 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist
}


#setup a busybox and dropbear in initramfs to be able to start the encrypted system via WoL if wanted

pacstrap base base-devel btrfs-tools

#differentiate between server setup /desktop /notebook setup
