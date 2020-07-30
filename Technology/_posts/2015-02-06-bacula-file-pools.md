---
layout: post
categories: []
tags: [backups, bacula]
author: Jackson Argo
---

[Bacula](http://blog.bacula.org/) is powerful and scalable open source backup software. Bacula has excellent integration with tape backups, and combined with its scalability, Bacula makes an great choice for enterprise backups. Since hard disks and NAS machines are now very cheap and reliable, backing up you data to hard disks has become a viable alternative to tapes. Bacula also supports backups to disks, but configuring this can seem a little weird since the Bacula software and documentation is written from the perspective of tape backups. For this tutorial, I will show you how to manage your backups to disk using file pools with Bacula.

### Creating the File Pools

The first thing we have to do is create the file pools. If you are doing tape backups, then you will likely have a designated group, or pool, of tapes for full backups, one for incremental backups, and one for differential backups. We can simulate these tape pools by designating a prefix for each pool a file belongs to. For example, an incremental backup will be written to files prefixed with **incr** using the Label Format option in the Pool directive.

        Pool {
            Name = IncrementalPool
            Pool Type = Backup
            Label Format = "incr"
        }



Bacula writes data in volumes and stores the volumes in files or on tapes. Unlike a tape which typically only holds 100-500GB of data and then gets replaced, a single file in a 24TB raid array can grow until it fills the entire filesystem and there isn't another raid array to replace it. We also have a practically unlimited amount of files that we can use, unless you have specifically tuned your filesystem's inode table. We can tell Bacula to write only one backup job to each volume and use one volume per file with **Max Volume Jobs = 1** and **Use Volume Once = yes**. This allows us to easily control the number of volumes Bacula is using and actually see them as files if we list the directory contents.

        Pool {
            Name = IncrementalPool
            Pool Type = Backup
            Label Format = "incr"
            Use Volume Once = yes
            Maximum Volume Jobs = 1
        }

### Managing the file pools

Finally, we want to manage the life-time of our volumes and the number of volumes so that we don't run out of disk space. You'll need a calculator for this part. After a few cycles of full, differential, and incremental backups, you can get an approximation of how much space each backup will take. A monthly cycle of full backups on the first Sunday, differentials on the other Sundays, and incrementals Monday through Saturday creates at most 1 full backup, 4 differential backups, 27 incremental backups. If you want to keep full backups for a year, differential for 6 months, and incremental for 3 months, then you need to have space to store 12 full, 24 differential, and 81 incremental backups. Otherwise, you'll have to adjust your schedule and volume life-time. You can limit the number of volumes Bacula can use in a pool with the Max Volumes option. By default, Bacula wont destroy old volumes, but you can tell it to overwrite them with new jobs using Recycle = yes. We'll also use Auto Prune = yes to tell Bacula to automatically prune old volumes for recycling.

You may also want to see my article here on optimizing your ext4 filesystem for backups.

Here is a complete example of file pool resources in bacula-dir.conf:

        Pool {
            Name = FullPool
            Pool Type = Backup
            LabelFormat = "full"
            Maximum Volume Jobs = 1
            Use Volume Once = yes
            Max Volumes = 12
            Volume Retention = 1 year
            Recycle = yes
            AutoPrune = yes
        }
        Pool {
            Name = DifferentialPool
            Pool Type = Backup
            LabelFormat = "diff"
            Maximum Volume Jobs = 1
            Use Volume Once = yes
            Max Volumes = 24
            Volume Retention = 6 months
            Recycle = yes
            AutoPrune = yes
        }
        Pool {
            Name = IncrementalPool
            Pool Type = Backup
            LabelFormat = "incr"
            Maximum Volume Jobs = 1
            Use Volume Once = yes
            Max Volumes = 81
            Volume Retention = 3 months
            Recycle = yes
            AutoPrune = yes
        }
