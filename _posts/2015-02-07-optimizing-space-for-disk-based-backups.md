---
layout: post
categories: []
tags: [filesystems, bacula, backups]
author: Jackson Argo
---

For this article, I want to show you how to optimize your ext4 partition for backups with Bacula. I suggest you also read my article on configuring file pools with Bacula here.

In my previous post, I mentioned that you practically have an unlimited amount files you can create. This is usually true because when you create an ext4 filesystem, the inode table is created with one inode per 16384 bytes by default. Each inode is 256 bytes, and for a large filesystem, the inode table can take up sizeable amount of space. For instance, if you have a 24TB filesystem, the inode table will take up ~375 GB by default. If know you only need a couple hundred inodes, then be a little generous and make 32,768 (2^15) inodes that take up a grand total of 8MB. Use the -N option to specify the number of inodes when you make the filesystem. Keep in mind that ext4 will use ~10 inodes for it’s own information and at least 1 for the journal, and **YOU CANNOT CHANGE THE NUMBER OF INODES ONCE THE FILESYSTEM IS CREATED**, so it is absolutely critical that you choose the right number.

Savings by limiting inodes: 1.5% or 325GB on a 24TB filesystem

Ext4 also reserves 5% of the disk space for the super-user by default. This allows breathing room for daemons in case the disk does completely fill up, and also helps prevent disk fragmentation. However, if we are only using this filesystem for backups, we don’t need this breathing room and we will likely not need to worry about disk fragmentation. This will save us ~1.2TB on a 24TB filesystem. Use the -m option to set the percentage of space reserved for the super-user.

Savings with no reserved space: 5% or 1.2TB on a 24TB filesystem.

Total Savings: 6.5% or 1.5TB on a 24TB filesystem.

There are performance optimization options to consider, but most of the relevant ones will be turned on automatically. You could also save a little more space by turning of some features such as the on-line resizing, but you don’t get much space (~1GB) for a handy feature if you ever want to increase the size of your array.

Here is a complete example for creating an optimized ext4 filesystem.

        # mkfs.ext4 -m 0 -n 32,768 /dev/mdX
