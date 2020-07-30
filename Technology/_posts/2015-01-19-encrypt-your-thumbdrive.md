---
layout: post
categories: []
tags: [filesystems, luks, encryption]
author: Jackson Argo
---

Thumb drives are handy devices for many occasions, but it is easy to fill them up with sensitive information without realizing it. This isn't a problem so long as we keep up with our little device. But if we accidentally misplace it or drop it, that sensative information is available to whoever happens to walk by and pick it up. The solution: an encrypted thumb drive!

We will use cryptsetup, which was likely installed with your system, to create a LUKS, or Linux Unified Key Setup, device. Unlike the name suggests, this is actually pretty portable. The encryption happens at the read-write level; data is encrypted as it is written and decrypted as it is read. Assuming your device is /dev/sdX, have a password in mind and format the device. This process WILL IRREVOCABLY ERASE ALL DATA ON THE DRIVE YOU ENCRYPT so be sure to make backups and type carefully.


        # cryptsetup luksFormat /dev/sdX


Now open the ecrypted device.


        # cryptsetup luksOpen /dev/sdX name


The device is mapped to /dev/mapper/<strong>name</strong> and serves as any other block device, and as with any block device, we need to make a filesystem on it before we can save anything to it.


        # mkfs.ext4 /dev/mapper/name


Now we can mount it where ever we want and use it like a normal drive. Gnome 3 supports automounting of these devices (it prompts you for the password of course), making this a very convinient and secure way to keep data on our thumb drives. The capabilities of LUKS devices extend far beyond simple thumb drive encryption and I suggest that you take a look at the man pages and online sources for more ideas for encrypting your data.
