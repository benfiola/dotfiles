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
pacstrap -K /mnt base linux linux-headers linux-firmware vim lvm2 grub-bios efibootmgr sudo networkmanager
# NOTE: amd CPU, install deps
pacstrap /mnt amd-ucode
# NOTE: nvidia GPU, install deps
pacstrap /mnt nvidia nvidia-dkms
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

# enable sudoers via wheel group
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/01-enable-wheel-sudo

# recreate initramfs
vim /etc/mkinitcpio.conf
# add lvm2 (before filesystems) to HOOKS
# NOTE: nvidia GPU, add nvidia nvidia_modeset nvidia_uvm nvidia_drm to MODULES
mkinitcpio -P

# NOTE: nvidia GPU, add pacman hook
mkdir -p /etc/pacman.d/hook
vim /etc/pacman.d/hooks/nvidia.hook
# find hook here: https://wiki.archlinux.org/title/NVIDIA

# NOTE: arm64, ensure grub can find initramfs
echo "GRUB_EARLY_INITRD_LINUX_CUSTOM=initramfs-linux.img" >> /etc/default/grub

# install bootloader
# NOTE: x86_64, use x86_64-efi target
# NOTE: arm, use arm64-efi target
grub-install --target=x86_64-efi --efi-directory=/boot
grub-mkconfig -o /boot/grub/grub.cfg

# enable services
systemctl enable NetworkManager

# reboot