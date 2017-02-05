
= original
= Arch Linux step-by-step installation =
= http://blog.fabio.mancinelli.me/2012/12/28/Arch_Linux_on_BTRFS.html =

= modified by jens heinrich


== Boot the installation CD ==

== Create partition ==

case hand:
gdisk /dev/sda
 * Create a partition with code ef02 (BIOS boot partition) 1MiB /dev/sda1
 * Create a partition with code 8300 (Linux) 500 MiB /boot /dev/sda2
 * Create a partition with code ef00 (EFI Partition) 300MiB /boot/efi /dev/sda3
if windows:
 * Create a partition with code 0c01 (Microsoft Reserved) 128 MiB /dev/sda4
endif
 * Create a partition with code 8200 (Linux SWAP) 4 GiB /dev/sda5
 * Create a partition with code 8300 (Linux) /dev/sda6

case auto:
sgdisk --zap-all
sgdisk --mbrtogpt /dev/sda
sgdisk --new=1:0:+1MiB 
sgdisk --type-code=1:ef02
sgdisk --change-name=1:"BIOS"
sgdisk --new=2:+128:+500MiB 
sgdisk --type-code=2:8300
sgdisk --change-name=2:"Boot"
sgdisk --new=3:+128:+300MiB 
sgdisk --type-code=3:ef00 
sgdisk --change-name=3:"EFI"
if windows
sgdisk --new=4:+128:+128MiB 
sgdisk --type-code=4:0c01
sgdisk --change-name=4:"Microsoft"
endif
sgdisk --new=5:+128:+4GiB 
sgdisk --type-code=5:8200
sgdisk --change-name=5:"Swap"
sgdisk --new=6:+128:-128MiB 
sgdisk --type-code=6:8300
sgdisk --change-name=6:"OS"



== Mount Swap ==
swapon /dev/sda5

== Format the partition ==

mkfs.btrfs -L "Arch Linux" /dev/sda6

== Mount the partition ==

mkdir /mnt/btrfs-root
mount -o defaults,relatime,discard,ssd,nodev,nosuid /dev/sda6 /mnt/btrfs-root

== Create the subvolumes ==

mkdir -p /mnt/btrfs/__snapshot
mkdir -p /mnt/btrfs/__current
btrfs subvolume create /mnt/btrfs-root/__current/ROOT
btrfs subvolume create /mnt/btrfs-root/__current/home
btrfs subvolume create /mnt/btrfs-root/__current/opt
btrfs subvolume create /mnt/btrfs-root/__current/var

== Mount the subvolumes ==

mkdir -p /mnt/btrfs-current

mount -o defaults,relatime,discard,ssd,nodev,subvol=__current/ROOT /dev/sda6 /mnt/btrfs-current
mkdir -p /mnt/btrfs-current/home
mkdir -p /mnt/btrfs-current/opt
mkdir -p /mnt/btrfs-current/var/lib

mount -o defaults,relatime,discard,ssd,nodev,nosuid,subvol=__current/home /dev/sda6 /mnt/btrfs-current/home
mount -o defaults,relatime,discard,ssd,nodev,nosuid,subvol=__current/opt /dev/sda6 /mnt/btrfs-current/opt
mount -o defaults,relatime,discard,ssd,nodev,nosuid,noexec,subvol=__current/var /dev/sda6 /mnt/btrfs-current/var

mkdir -p /mnt/btrfs-current/var/lib
mount --bind /mnt/btrfs-root/__current/ROOT/var/lib /mnt/btrfs-current/var/lib

== Install Arch Linux ==

nano /etc/pacman.d/mirrorlist 
 * Select the mirror to be used

pacstrap /mnt/btrfs-current base base-devel
genfstab -U -p /mnt/btrfs-current >> /mnt/btrfs-current/etc/fstab
vi /mnt/btrfs-current/etc/fstab
 * add "tmpfs /tmp tmpfs nodev,nosuid 0 0"
 * add "tmpfs /dev/shm tmpfs nodev,nosuid,noexec 0 0"
 * copy the partition info for / and mount it on /run/btrfs-root (remember to remove subvol parameter! and add nodev,nosuid,noexec parameters)
 * remove the /var/lib entry (we will bind it)
 * add "/run/btrfs-root/__current/ROOT/var/lib	/var/lib none bind 0 0" (to bind the /var/lib on the var subvolume to the /var/lib on the ROOT subvolume)S 

== Configure the system ==
 
arch-chroot /mnt/btrfs-current

pacman -S btrfs-progs

vi /etc/locale.gen
 * Uncomment en_US.UTF-8
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
. /etc/locale.conf

ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc --utc

echo nemesis > /etc/hostname
nano /etc/nsswitch
 * set the hostname

pacman -S wicd
systemctl enable wicd.service

nano /etc/mkinitcpio.conf
 * Remove fsck and add btrfs to HOOKS
mkinitcpio -p linux

passwd
groupadd jens
useradd -m -g jens -G users,wheel,storage,power,network -s /bin/bash -c "Jens Heinrich" jens
passwd jens

pacman -S sudo
visudo
 * Enable sudo for wheel

== Install boot loader ==

pacman -S grub-bios
grub-install --target=i386-pc --recheck /dev/sda
nano /etc/default/grub
 * Edit settings (e.g., disable gfx, quiet, etc.)
grub-mkconfig -o /boot/grub/grub.cfg

== Unmount and reboot ==

exit

umount /mnt/btrfs-current/home
umount /mnt/btrfs-current/opt
umount /mnt/btrfs-current/var/lib
umount /mnt/btrfs-current/var
umount /mnt/btrfs-current
umount /mnt/btrfs-root

reboot

== Post installation configuration ==

=== Power management ===

nano /etc/modprobe.d/blacklist.conf
 * blacklist nouveau

Download and compile bbswitch from https://aur.archlinux.org/packages/bbswitch/

nano /etc/mkinitcpio.conf
 * Add "i915 bbswitch" to MODULES
 * Add "/etc/modprobe.d/i915.conf /etc/modprobe.d/bbswitch.conf" to FILES
nano /etc/modprobe.d/i915.conf
 options i915 modeset=1
 options i915 i915_enable_rc6=1
 options i915 i915_enable_fbc=1
 options i915 lvds_downclock=1
nano /etc/modprobe.d/bbswitch.conf
 options bbswitch load_state=0
 options bbswitch unload_state=1
mkinitcpio -p linux

=== Hardening ===

chmod 700 /boot /etc/{iptables,arptables}

nano /etc/securetty
 * Comment tty1

nano /etc/iptables/iptables.rules
 *filter
 :INPUT DROP [0:0]
 :FORWARD DROP [0:0]
 :OUTPUT ACCEPT [0:0]
 -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT 
 -A INPUT -i lo -j ACCEPT 
 -A INPUT -p udp --sport 53 -j ACCEPT
 -A INPUT -p icmp -j REJECT
 -A INPUT -p tcp -j REJECT --reject-with tcp-reset 
 -A INPUT -p udp -j REJECT --reject-with icmp-port-unreachable 
 -A INPUT -j REJECT --reject-with icmp-proto-unreachable 
 COMMIT
systemctl enable iptables.service

nano /etc/sysctl.conf
 * net.ipv4.conf.all.log_martians = 1
 * net.ipv4.conf.all.rp_filter = 1
 * net.ipv4.icmp_echo_ignore_broadcasts = 1
 * net.ipv4.icmp_ignore_bogus_error_responses = 1

=== Snapshot ===

echo `date "+%Y%m%d-%H%M%S"` > /run/btrfs-root/__current/ROOT/SNAPSHOT
echo "Fresh install" >> /run/btrfs-root/__current/ROOT/SNAPSHOT
btrfs subvolume snapshot -r /run/btrfs-root/__current/ROOT /run/btrfs-root/__snapshot/ROOT@`head -n 1 /run/btrfs-root/__current/ROOT/SNAPSHOT`
cd /run/btrfs-root/__snapshot/
ln -s ROOT@`cat /run/btrfs-root/__current/ROOT/SNAPSHOT` fresh-install
rm /run/btrfs-root/__current/ROOT/SNAPSHOT 

