# create partitions
parted /dev/sda
> mktable gpt
> mkpart primary fat32 0% 512MB
> set 1 esp on
> mkpart primary 512MB -8GB
> set 2 lvm on
> mkpart primary linux-swap -8GB 100%
> quit

# create lvm
pvcreate /dev/sda2
vgcreate vg-os /dev/sda2
lvcreate -L 1G -n os vg-os
lvextend -l +100%FREE /dev/vg-os/os

# format partitions
mkfs.fat -F 32 /dev/sda1
mkfs.ext4 /dev/vg-os/os
mkswap /dev/sda3

# mount partitions
swapon /dev/sda3
mkdir -p /mnt
mount /dev/vg-os/os /mnt
mount --mkdir /dev/sda1 /mnt/boot

# install packages
pacstrap -K /mnt base linux linux-headers linux-firmware vim man-db man-pages lvm2 grub-bios efibootmgr sudo networkmanager sbctl refind
# NOTE: amd CPU, install deps
pacstrap /mnt amd-ucode
# NOTE: nvidia GPU, install deps
pacstrap /mnt nvidia nvidia-dkms nvidia-settings
# NOTE: arm, install arm64 deps
pacstrap /mnt archlinuxarm-keyring

# generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# chroot the install root
arch-chroot /mnt

# NOTE: arm, set arch linux arm repo key as trusted
pacman-key --init 
pacman-key --populate archlinuxarm

# set hostname
echo "arch" > /etc/hostname

# create user
useradd --create-home bfiola
usermod -aG wheel bfiola
passwd bfiola
chfn -f "Ben Fiola" bfiola

# enable sudoers via wheel group
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/01-enable-wheel-sudo

# recreate initramfs
vim /etc/mkinitcpio.conf
# add lvm2 (before filesystems) to HOOKS
# add resume (after lvm2) to HOOKS
# NOTE: nvidia GPU, add nvidia nvidia_modeset nvidia_uvm nvidia_drm to MODULES
mkinitcpio -P

# NOTE: nvidia GPU, add pacman hook
mkdir -p /etc/pacman.d/hooks
vim /etc/pacman.d/hooks/nvidia.hook
# find hook here: https://wiki.archlinux.org/title/NVIDIA

# install refind
refind-install

# configure /boot/EFI/refind/refind.conf
#
# disable autodiscovery of linux kernels for this installation
# get PARTUUID (run `blkid` with boot partition)
# then, set (no quotes): dont_scan_volumes [partuuid]
#
# add manual entry for this installation
# menuentry "Arch Linux" {
#     icon     /EFI/refind/icons/os_arch.png
#     volume   "Arch Linux"
#     loader   /vmlinuz-linux
#     initrd   /initramfs-linux.img
#     options  "root=/dev/mapper/vg--os-os rw loglevel=3 quiet"
#     submenuentry "Boot using fallback initramfs" {
#         initrd /boot/initramfs-linux-fallback.img
#     }
# }
# for hibernation, get UUID (run `blkid` with swap partition)
# then, add to options (no quotes): resume=UUID=[uuid]
# NOTE: nvidia GPU, add to options: nvidia_drm.modeset=1

# set up secure boot
sbctl create-keys
sbctl enroll-keys -m
sbctl sign -s /boot/vmlinuz-linux
sbctl sign -s /boot/EFI/refind/refind_x64.efi
sbctl verify

# enable services
systemctl enable NetworkManager

# reboot
# NOTE: dual booting windows, instruct arch to use local time w/ hw clock
timedatectl set-local-rtc 1
