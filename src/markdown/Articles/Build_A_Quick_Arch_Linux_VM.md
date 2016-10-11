
Arch Linux is a great OS for bleeding-edge development since it uses a rolling release model, always has the latest packages available, and is extremely light-weight. Arch Linux also provides very intuitive software to automate building packages from source code, and most packages that aren’t in the official repositories can be found in the Arch User Repository (AUR). For this tutorial, I’ll show you how make a quick Arch Linux virtual machine using Virtual Box. For an added level of portability, we’ll avoid using a text editor through the entire installation and confiuration process.

Grab the install image, fire up Virtual Box, and create a new VM. The defaults settings from the Arch Linux template are fine; mine uses 512MB of memory and an 8GB hard drive. The install image boots into a zsh shell that has some extra bells and whistles, and this will likely be the only time you’ll run into this level of extravagance out-of-the-box with Arch. I typically just switch to a simple bash shell, but feel free to explore this shell.

Arch Linux provides a few install scripts, but those are mostly unnecessary and take away from the full ground-up experience. The first thing we’ll tackle is the partition table and filesystem. Virtual Box provides bios, so unless you are trying to prepare something special, we can just make a simple dos type partition table with a swap and root partition using fdisk or parted.

        # parted /dev/sda mklabel msdos
        # parted /dev/sda mkpart primary linux-swap 1M 1G
        # parted /dev/sda mkpart primary ext4 1G 100%

Make the filesystems and mount them under /mnt. We’ll also mount a few other important filesystems. If you chose to use efi instead of bios for booting, then you’ll also want to mount any efi specific partitions.

        # mkswap /dev/sda1
        # swapon /dev/sda1
        # mkfs.ext4 /dev/sda2
        # mount /dev/sda2 /mnt
        # mkdir /mnt/{dev,proc,sys}
        # mount -t proc proc /mnt/proc
        # mount -t sysfs sys /mnt/sys
        # mount -o bind /dev /mnt/dev

Write the partition setup to /mnt/etc/fstab.

        # mkdir /mnt/etc
        # echo '/dev/sda1 none swap defaults 0 0' >> /mnt/etc/fstab
        # echo '/dev/sda2 / ext4 defaulst 0 1' >> /mnt/etc/fstab

Now we are ready to install Arch Linux. All the packages needed for a (seriously) minimal Linux installation are provided by the base meta-package and can be installed with pacman. We will have to add some directories that pacman expects before it will run. The install image doesn’t have any packages on it, so you’ll have to be connected to the internet to download them. If the network adapter is using NAT (the default) then you don’t have to do anything special.

        # mkdir -p /mnt/var/lib/pacman
        # pacman --root /mnt -Sy base

For the rest of the configuration, we’ll chroot into our system. We will have to download a few things later, so copy over the resolvconf file before we chroot .

        # cp /etc/resolv.conf /mnt/etc

The base package group doesn’t include the zsh shell so we’re leaving it for good now.

        # chroot /mnt bash

Set the hostname, locale, time zone, and root password.

        # echo myhost > /etc/hostname
        # echo 'en_US.UTF-8' > /etc/locale.gen && locale-gen
        # echo 'LANG=en_US.UTF-8' > /etc/locale.conf
        # ln -s /usr/share/zoneinfo/US/Eastern /etc/localtime
        # echo 'MyPass' | passwd --stdin

Next we’ll configure pacman. To make things simple, we’ll just copy the configuration files from the install image.

        # exit
        # cp /etc/pacman.conf /mnt/etc
        # cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d
        # chroot /mnt bash

Pacman uses gpg to verify packages, and we’ll also have to initialize the pacman key ring.

        # pacman-key --init
        # pacman-key --populate

All that is left to do is to make the init ram disk and configure a boot loader. Both the Grub and Syslinux packages have automated install scripts for an msdos MBR making them very quick solutions, but Syslinux is a little lighter, so we’ll use that one.

        # mkinitcpio -p linux
        # pacman -S syslinux
        # syslinux-install_update -i -a -m

The Syslinux install script assumes that the root partition is on /dev/sda3, but our setup has it on /dev/sda2. We can use sed to fix it. Who needs text editors anyways?

       # sed -i 's/sda3/sda2/' /boot/syslinux/syslinux.cfg

That’s it. Reboot and you’ll have a fresh Arch Linux VM to play with.
