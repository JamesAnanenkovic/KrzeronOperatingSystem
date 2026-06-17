#!/usr/bin/env python3
"""Build a FAT12 floppy image with test files."""

import struct
import subprocess
import sys
import os

FAT12_IMG = 'build/fat12.img'
FILES = {
    'README  TXT': b'kr0nos Operating System\n'
                   b'=======================\n'
                   b'Version: 0.0.B\n'
                   b'FAT12 filesystem driver working!\n',
    'HELLO   TXT': b'Hello from FAT12!\n'
                   b'This is a test file on the kr0nos filesystem.\n',
    'CMDS    TXT': b'Available commands:\n'
                   b'  help, about, exit, read, uname, sysinfo\n'
                   b'  uptime, sleep, version, reboot, clr\n'
                   b'  free, testalloc, ls, cat\n',
}


def main():
    os.makedirs('build', exist_ok=True)

    # Create a 1.44MB image
    size = 2880 * 512
    with open(FAT12_IMG, 'wb') as f:
        f.seek(size - 1)
        f.write(b'\x00')

    # Try mtools first
    try:
        subprocess.run(['mkfs.fat', '-F', '12', FAT12_IMG], check=True,
                       capture_output=True)
        for name_83, content in FILES.items():
            # Write via Python directly (mtools may not be available)
            inject_file_to_fat12(FAT12_IMG, name_83, content)
        return
    except (FileNotFoundError, subprocess.CalledProcessError):
        # Fall through to pure-Python builder
        pass

    # Pure Python FAT12 builder
    mkfs_fat12_python(FAT12_IMG, FILES)


def inject_file_to_fat12(img_path, name_83, content):
    """Inject a file into a pre-formatted FAT12 image by patching the
    root directory and FAT, and writing data to the data area."""
    with open(img_path, 'rb+') as f:
        data = f.read()
        f.seek(0)

        # Parse BPB
        bps = struct.unpack_from('<H', data, 11)[0]
        spc = struct.unpack_from('<B', data, 13)[0]
        resvd = struct.unpack_from('<H', data, 14)[0]
        fats = struct.unpack_from('<B', data, 16)[0]
        root_entries = struct.unpack_from('<H', data, 17)[0]
        sec_per_fat = struct.unpack_from('<H', data, 22)[0]
        root_dir_sec = resvd + fats * sec_per_fat
        root_dir_sectors = (root_entries * 32 + bps - 1) // bps
        first_data_sec = root_dir_sec + root_dir_sectors

        # Find a free directory entry
        dir_entry_size = 32
        root_dir_offset = root_dir_sec * bps
        free_off = None
        for i in range(root_entries):
            off = root_dir_offset + i * dir_entry_size
            first_byte = data[off]
            if first_byte in (0, 0xE5):
                free_off = off
                break

        if free_off is None:
            raise RuntimeError('Root directory full')

        # Allocate clusters for the file
        bytes_per_cluster = spc * bps
        clusters_needed = (len(content) + bytes_per_cluster - 1) // bytes_per_cluster
        clusters = find_free_clusters(data, clusters_needed, resvd, sec_per_fat, fats, bps)

        # Write data to data area
        data_area_off = first_data_sec * bps
        cluster_idx = 0
        bytes_written = 0
        for cl in clusters:
            cl_off = data_area_off + (cl - 2) * bytes_per_cluster
            chunk = content[bytes_written:bytes_written + bytes_per_cluster]
            # Write from the copy
            arr = bytearray(data)
            arr[cl_off:cl_off + len(chunk)] = chunk
            bytes_written += len(chunk)

        # Write directory entry
        entry = bytearray(32)
        name_83_bytes = name_83.encode('ascii')
        entry[0:11] = name_83_bytes
        entry[11] = 0x20  # Archive attribute
        struct.pack_into('<H', entry, 26, clusters[0])
        struct.pack_into('<I', entry, 28, len(content))
        arr[free_off:free_off + 32] = entry

        # Update FAT
        fat_off = resvd * bps
        for i, cl in enumerate(clusters):
            next_cl = clusters[i + 1] if i + 1 < len(clusters) else 0xFFF
            set_fat12_entry(arr, fat_off, cl, next_cl)

        f.seek(0)
        f.write(arr)


def find_free_clusters(data, count, resvd, sec_per_fat, fats, bps):
    """Find free clusters in the FAT."""
    fat_off = resvd * bps
    max_cluster = (sec_per_fat * bps * 2) // 3  # approx
    clusters = []
    for cl in range(2, max_cluster):
        val = get_fat12_entry(data, fat_off, cl)
        if val == 0:
            clusters.append(cl)
            if len(clusters) == count:
                return clusters
    raise RuntimeError('Not enough free clusters')


def get_fat12_entry(data, fat_off, cluster):
    """Read a 12-bit FAT entry."""
    off = fat_off + (cluster * 3 // 2)
    raw = struct.unpack_from('<H', data, off)[0]
    if cluster & 1:
        return raw >> 4
    else:
        return raw & 0x0FFF


def set_fat12_entry(data, fat_off, cluster, value):
    """Write a 12-bit FAT entry."""
    off = fat_off + (cluster * 3 // 2)
    raw = struct.unpack_from('<H', data, off)[0]
    if cluster & 1:
        raw = (raw & 0x000F) | (value << 4)
    else:
        raw = (raw & 0xF000) | (value & 0x0FFF)
    struct.pack_into('<H', data, off, raw)


def mkfs_fat12_python(img_path, files):
    """Create a full FAT12 1.44MB floppy image from scratch."""
    bps = 512
    spc = 1
    resvd = 1
    fats = 2
    root_entries = 224
    total_sectors = 2880
    sec_per_fat = 9

    root_dir_sec = resvd + fats * sec_per_fat
    root_dir_sectors = (root_entries * 32 + bps - 1) // bps
    first_data_sec = root_dir_sec + root_dir_sectors
    data_sectors = total_sectors - first_data_sec
    total_clusters = data_sectors // spc

    img = bytearray(total_sectors * bps)

    # Boot sector
    bs = bytearray(512)
    bs[0:3] = b'\xEB\x3C\x90'
    bs[3:11] = b'kr0nos  '
    struct.pack_into('<H', bs, 11, bps)     # bytes per sector
    struct.pack_into('<B', bs, 13, spc)      # sectors per cluster
    struct.pack_into('<H', bs, 14, resvd)    # reserved sectors
    struct.pack_into('<B', bs, 16, fats)     # FAT count
    struct.pack_into('<H', bs, 17, root_entries)  # root entries
    struct.pack_into('<H', bs, 19, total_sectors) # total sectors
    struct.pack_into('<B', bs, 21, 0xF0)     # media descriptor
    struct.pack_into('<H', bs, 22, sec_per_fat)   # sectors per FAT
    struct.pack_into('<H', bs, 24, 18)       # sectors per track
    struct.pack_into('<H', bs, 26, 2)        # heads
    struct.pack_into('<I', bs, 28, 0)        # hidden sectors
    bs[510:512] = b'\x55\xAA'
    img[0:512] = bs

    # FAT tables (2 copies)
    fat = bytearray(sec_per_fat * bps)
    # Cluster 0: media descriptor + padding
    set_fat12_entry(fat, 0, 0, 0xFF0)
    set_fat12_entry(fat, 0, 1, 0xFFF)

    # Allocate clusters for each file
    bytes_per_cluster = spc * bps
    next_free_cluster = 2
    root_dir = bytearray(root_dir_sectors * bps)
    entry_idx = 0

    for name_83, content in files.items():
        if entry_idx >= root_entries:
            print(f'Warning: root dir full, skipping {name_83}')
            break

        clusters_needed = max(1, (len(content) + bytes_per_cluster - 1) // bytes_per_cluster)
        clusters = list(range(next_free_cluster, next_free_cluster + clusters_needed))
        next_free_cluster += clusters_needed

        # Write data
        data_off = first_data_sec * bps
        for i, cl in enumerate(clusters):
            cl_off = data_off + (cl - 2) * bytes_per_cluster
            chunk = content[i * bytes_per_cluster:(i + 1) * bytes_per_cluster]
            img[cl_off:cl_off + len(chunk)] = chunk

            # FAT chain
            next_val = clusters[i + 1] if i + 1 < len(clusters) else 0xFFF
            set_fat12_entry(fat, 0, cl, next_val)

        # Directory entry
        off = entry_idx * 32
        name_83_bytes = name_83.encode('ascii')
        root_dir[off:off + 11] = name_83_bytes
        root_dir[off + 11] = 0x20  # Archive
        struct.pack_into('<H', root_dir, off + 26, clusters[0])
        struct.pack_into('<I', root_dir, off + 28, len(content))
        entry_idx += 1

    img[root_dir_sec * bps:root_dir_sec * bps + len(root_dir)] = root_dir
    img[resvd * bps:resvd * bps + len(fat)] = fat
    img[(resvd + sec_per_fat) * bps:(resvd + sec_per_fat) * bps + len(fat)] = fat

    with open(img_path, 'wb') as f:
        f.write(img)

    print(f'Created {img_path}: {len(files)} files, {total_clusters} clusters')


if __name__ == '__main__':
    main()
