# LVM Flow chart
A flow chart for changing disk space via lvm.

## Adding space to a filesystem

1. Is there space in the volume group?

        # vgs
          VG         #PV #LV #SN Attr   VSize  VFree
          volgroup00   2   1   0 wz--n- 19.99g 9.99g

 * If yes, skip to 17.
 * If no, continue to 2.

2. Are the physical volumes in the volume group on partitions?

        # pvs
          PV         VG         Fmt  Attr PSize  PFree 
          /dev/xvdb1 volgroup00 lvm2 a--  10.00g 10.00g
          /dev/xvdb2 volgroup00 lvm2 a--  10.00g 10.00g
          /dev/xvdc  volgroup01 lvm2 a--  25.00g 25.00g

 This is a device with partitions:
 
        # parted /dev/xvdb unit gib print
        Model: Xen Virtual Block Device (xvd)
        Disk /dev/xvdb: 50.0GiB
        Sector size (logical/physical): 512B/512B
        Partition Table: gpt
        Disk Flags: 

        Number  Start    End      Size     File system  Name     Flags
         1      0.00GiB  10.0GiB  10.0GiB               primary  lvm
         2      10.0GiB  20.0GiB  10.0GiB               primary  lvm

 This is a device without partitions:
 
        # parted /dev/xvdc unit gib print
        Error: /dev/xvdc: unrecognised disk label
        Model: Xen Virtual Block Device (xvd)                                     
        Disk /dev/xvdc: 50.0GiB
        Sector size (logical/physical): 512B/512B
        Partition Table: unknown
        Disk Flags: 

 * If yes, skip to 13.
 * If no, continue to 3.

3. Is the device entire used?

        # pvs
          PV         VG         Fmt  Attr PSize  PFree 
          /dev/xvdc  volgroup01 lvm2 a--  25.00g 25.00g

        # parted /dev/xvdc unit gib print
        Error: /dev/xvdc: unrecognised disk label
        Model: Xen Virtual Block Device (xvd)                                     
        Disk /dev/xvdc: 50.0GiB
        Sector size (logical/physical): 512B/512B
        Partition Table: unknown
        Disk Flags: 

 * If yes, continue to 4.
 * If no, skip to 7.

4. Can you increase the size of the device?
 * If yes, continue to 5.
 * If no, skip to 9.

5. Increase the size of the device.

6. Rescan the device so the kernel recognizes the new size.

        echo 1 > /sys/block/xvdc/device/rescan
        
7. Increase the size of the physical volume.

        # vgs
          VG         #PV #LV #SN Attr   VSize  VFree 
          volgroup01   1   0   0 wz--n- 25.00g 25.00g

        # pvs
          PV         VG         Fmt  Attr PSize  PFree 
          /dev/xvdc  volgroup01 lvm2 a--  25.00g 25.00g
          
        # pvresize /dev/xvdc
          Physical volume "/dev/xvdc" changed
          1 physical volume(s) resized / 0 physical volume(s) not resized

        # pvs
          PV         VG         Fmt  Attr PSize  PFree 
          /dev/xvdc  volgroup01 lvm2 a--  50.00g 50.00g
          
        # vgs
          VG         #PV #LV #SN Attr   VSize  VFree 
          volgroup01   1   0   0 wz--n- 50.00g 50.00g
          
8. Skip to 17.

9. Add a new device.

10. Scan the scsi host for the new device.

        # echo "- - -" > /sys/class/scsi_host/host0/scan

11. Create a partition on the new device.

        # parted /dev/xvdc mklabel gpt
        # parted /dev/xvdc mkpart primary 0% 100%

12. Go to 15.

13. Is there space available to add a new partition?
 * If yes, continue to 14.
 * If no, go to 9.

 Using parted, we can check where the last filesystem ends and how much space is on the disk. 

        # parted /dev/xvdb unit gib print free
        Model: Xen Virtual Block Device (xvd)
        Disk /dev/xvdb: 50.0GiB
        Sector size (logical/physical): 512B/512B
        Partition Table: gpt
        Disk Flags: 

        Number  Start    End      Size     File system  Name     Flags
                0.00GiB  0.00GiB  0.00GiB  Free Space
         1      0.00GiB  10.0GiB  10.0GiB               primary  lvm
         2      10.0GiB  20.0GiB  10.0GiB               primary  lvm
                20.0GiB  50.0GiB  30.0GiB  Free Space

14. Use parted to create a new lvm partition.

        # parted /dev/xvdb unit gib print
        Model: Xen Virtual Block Device (xvd)
        Disk /dev/xvdb: 50.0GiB
        Sector size (logical/physical): 512B/512B
        Partition Table: gpt
        Disk Flags: 

        Number  Start    End      Size     File system  Name     Flags
         1      0.00GiB  10.0GiB  10.0GiB               primary  lvm
         2      10.0GiB  20.0GiB  10.0GiB               primary  lvm

        # parted /dev/xvdb mkpart primary 20GiB 30GiB
        
        # parted /dev/xvdb set 3 lvm on

        # parted /dev/xvdb unit gib print
        Model: Xen Virtual Block Device (xvd)
        Disk /dev/xvdb: 50.0GiB
        Sector size (logical/physical): 512B/512B
        Partition Table: gpt
        Disk Flags: 

        Number  Start    End      Size     File system  Name     Flags
         1      0.00GiB  10.0GiB  10.0GiB               primary  lvm
         2      10.0GiB  20.0GiB  10.0GiB               primary  lvm
         3      20.0GiB  30.0GiB  10.0GiB               primary  lvm
         
15. Use pvcreate to convert the new partition into a physical volume.

        # pvs
          PV         VG   Fmt  Attr PSize  PFree 
          /dev/xvdb1      lvm2 ---  10.00g 10.00g
          /dev/xvdb2      lvm2 ---  10.00g 10.00g

        # pvcreate /dev/xvdb3
        
        # pvs
          PV         VG   Fmt  Attr PSize  PFree 
          /dev/xvdb1      lvm2 ---  10.00g 10.00g
          /dev/xvdb2      lvm2 ---  10.00g 10.00g
          /dev/xvdb3      lvm2 ---  10.00g 10.00g

16. Use vgextend to extend the volume group with the new physical volume.

        # vgs
          VG         #PV #LV #SN Attr   VSize  VFree
          volgroup00   2   1   0 wz--n- 19.99g 9.99g
          
        # vgextend volgroup00 /dev/xvdb3
          Volume group "volgroup00" successfully extended
 
         # vgs
          VG         #PV #LV #SN Attr   VSize  VFree
          volgroup00   2   1   0 wz--n- 29.99g 19.99g

17. Use lvextend to increase the size of the logical partition.

        # lvs
          LV    VG         Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
          lvol0 volgroup00 -wi-a----- 10.00g

 We can extend with a specific size:
 
        # lvextend -L +5GiB /dev/mapper/volgroup00-lvol0 
          Size of logical volume volgroup00/lvol0 changed from 10.00 GiB (2560 extents) to 15.00 GiB (3840 extents).
          Logical volume lvol0 successfully resized.
          
        # lvs 
          LV    VG         Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
          lvol0 volgroup00 -wi-a----- 15.00g

 We can fill the entire device:

        # lvextend -l +100%FREE /dev/mapper/volgroup00-lvol0 
          Size of logical volume volgroup00/lvol0 changed from 15.00 GiB (3840 extents) to 29.99 GiB (7677 extents).
          Logical volume lvol0 successfully resized.

        # lvs 
          LV    VG         Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
          lvol0 volgroup00 -wi-a----- 29.99g

18. Use **resize2fs** or **xfs_growfs** to make the filesystem fill the partition.

 Resizing an **ext4** filesystem:

        # df -h /dev/volgroup00/lvol0
        Filesystem                    Size  Used Avail Use% Mounted on
        /dev/mapper/volgroup00-lvol0   20G   45M   19G   1% /mnt/volgroup00/lvol0

        # resize2fs /dev/volgroup00/lvol0
        resize2fs 1.42.9 (28-Dec-2013)
        Filesystem at /dev/volgroup00/lvol0 is mounted on /mnt/volgroup00/lvol0; on-line resizing required
        old_desc_blocks = 3, new_desc_blocks = 4
        The filesystem on /dev/volgroup00/lvol0 is now 7859200 blocks long.

        # df -h /dev/volgroup00/lvol0
        Filesystem                    Size  Used Avail Use% Mounted on
        /dev/mapper/volgroup00-lvol0   30G   44M   28G   1% /mnt/volgroup00/lvol0

 Reszing an **xfs** filesystem:
        
        # df -h /mnt/volgroup00/lvol0
        Filesystem                    Size  Used Avail Use% Mounted on
        /dev/mapper/volgroup00-lvol0   35G   33M   35G   1% /mnt/volgroup00/lvol0

        # xfs_growfs /dev/volgroup00/lvol0
        meta-data=/dev/mapper/volgroup00-lvol0 isize=256    agcount=5, agsize=1964800 blks
                 =                       sectsz=512   attr=2, projid32bit=1
                 =                       crc=0        finobt=0
        data     =                       bsize=4096   blocks=9169920, imaxpct=25
                 =                       sunit=0      swidth=0 blks
        naming   =version 2              bsize=4096   ascii-ci=0 ftype=0
        log      =internal               bsize=4096   blocks=3837, version=2
                 =                       sectsz=512   sunit=0 blks, lazy-count=1
        realtime =none                   extsz=4096   blocks=0, rtextents=0

        # df -h /mnt/volgroup00/lvol0
        Filesystem                    Size  Used Avail Use% Mounted on
        /dev/mapper/volgroup00-lvol0   42G   33M   42G   1% /mnt/volgroup00/lvol0

19. You are done!


