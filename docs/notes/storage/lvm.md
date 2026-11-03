# Storage — Logical Volume Management (LVM)

Domain: Storage ("Configure and manage LVM storage").

PV: Physical volumes
VG: Volume groups
LV: Logical volumes

## Physical volumes

The raw physical storage devices (e.g., /dev/sda1, /dev/nvme0n1) that you initialize so LVM can use them.

Commands:

- Create: pvcreate
- View(Summary): pvs
- View(Detailed): pvdisplay
- Extend/Grow: N/A
- Remove/Delete: pvremove

## Volume groups

The giant pool of storage created by combining one or more Physical Volumes together.

- Create: vgcreate
- View(Summary): vgs
- View(Detailed): vgdisplay
- Extend/Grow: vgextend
- Remove/Delete: vgremove

## Logical volumes

The actual partitions carved out of the Volume Group. You format these with a filesystem (like ext4 or xfs) and mount them to your system.

- Create: lvcreate
- View(Summary): lvs
- View(Detailed): lvdisplay
- Extend/Grow: lvextend
- Remove/Delete: lvremove

## LFCS exam example

Step 1: Initialize the Physical Volume (PV)

```
sudo pvcreate /dev/sdb
```

Verify: sudo pvs

Step 2: Create the Volume Group (VG)

Create a storage pool named vg_data using that disk.

```
sudo vgcreate vg_data /dev/sdb
```

Verify: sudo vgs

Step 3: Create the Logical Volume (LV)

Carve out a specific size from your pool. The exam usually specifies a strict size (e.g., exactly 5 Gigabytes).

```
sudo lvcreate -L 5G -n lv_storage vg_data
```

- Exam Tip: If they ask you to use all remaining space in the VG, use uppercase -l with a percentage: `sudo lvcreate -l 100%FREE -n lv_storage vg_data`.
- Verify: sudo lvs

Step 4: Format and Mount It

The path to your new volume will be /dev/vg_name/lv_name.

```
# 1. Format with the requested filesystem (ext4 or xfs)
sudo mkfs.ext4 /dev/vg_data/lv_storage

# 2. Create the mount point
sudo mkdir -p /mnt/storage

# 3. Mount it temporarily
sudo mount /dev/vg_data/lv_storage /mnt/storage
```

## Critical exam trap: persistent mounts (/etc/fstab)

If you reboot the system during grading and your LVM isn't mounted, you lose points. Always automate the mount.

```
sudo vi /etc/fstab
```

Add the configuration line at the bottom:

```
/dev/vg_data/lv_storage  /mnt/storage  ext4  defaults  0  2
```

Test your fstab immediately! Run `sudo umount /mnt/storage` and then:

```
sudo mount -a
```

## High-probability exam task: extending an LV

You will almost certainly be asked to expand an existing volume without losing data.
To grow lv_storage by an additional 2 Gigabytes and fix the filesystem at the same time, always use the `--resizefs` (or `-r`) flag. It works perfectly for both Ext4 and XFS:

```
sudo lvextend -L +2G /dev/vg_data/lv_storage --resizefs
```
