#!/usr/bin/env python3
"""Build a FAT12 floppy image with test files for kr0nos."""

import struct
import os
import sys
import subprocess

OUTPUT = sys.argv[1] if len(sys.argv) > 1 else "build/fat12.img"
FILES = {
    "README.TXT": b"kr0nos Operating System\n=======================\nVersion: 0.0.B\nFAT12 filesystem driver working!\n",
    "HELLO.TXT":  b"Hello from FAT12!\nThis is a test file on the kr0nos filesystem.\n",
    "CMDS.TXT":   (
        b"Available commands:\n"
        b"  help, about, exit, read, uname, sysinfo\n"
        b"  uptime, sleep, version, reboot, clr\n"
        b"  free, testalloc, ls, cat\n"
    ),
}

def build_fat12_python(outfile):
    """Build a FAT12 image using pure Python."""
    # Floppy geometry
    bytes_per_sec = 512
    sec_per_cluster = 1
    reserved_sec = 1
    fat_count = 2
    root_entries = 224
    total_sec = 2880
    sec_per_fat = 9

    root_dir_sectors = (root_entries * 32 + bytes_per_sec - 1) // bytes_per_sec
    first_data_sec = reserved_sec + (fat_count * sec_per_fat) + root_dir_sectors
    data_sec = total_sec - first_data_sec
    total_clusters = data_sec // sec_per_cluster

    image = bytearray(total_sec * bytes_per_sec)

    # BPB
    bpb = bytearray(512)
    bpb[0:3] = b"\xeb\x3c\x90"  # jmp + nop
    bpb[3:11] = b"KR0NOS  "      # OEM
    struct.pack_into("<H", bpb, 11, bytes_per_sec)
    bpb[13] = sec_per_cluster
    struct.pack_into("<H", bpb, 14, reserved_sec)
    bpb[16] = fat_count
    struct.pack_into("<H", bpb, 17, root_entries)
    struct.pack_into("<H", bpb, 19, total_sec)
    bpb[21] = 0xF0              # media descriptor
    struct.pack_into("<H", bpb, 22, sec_per_fat)
    struct.pack_into("<H", bpb, 24, 18)  # sec_per_track
    struct.pack_into("<H", bpb, 26, 2)   # heads
    struct.pack_into("<I", bpb, 28, 0)   # hidden sectors
    struct.pack_into("<I", bpb, 32, 0)   # total large sectors

    # Extended BPB (FAT12)
    bpb[36] = 0x00              # drive number
    bpb[37] = 0x00              # reserved
    bpb[38] = 0x29              # boot signature
    struct.pack_into("<I", bpb, 39, 0x12345678)  # volume serial
    bpb[43:54] = b"KR0NOS     " # volume label (11 bytes)
    bpb[54:62] = b"FAT12   "    # filesystem type

    # Boot signature
    bpb[510] = 0x55
    bpb[511] = 0xAA

    image[0:512] = bpb

    # FATs
    fat_offset = reserved_sec * bytes_per_sec
    # Cluster 0: 0xFF0 (media type), Cluster 1: 0xFFF (end-of-chain)
    fat_data = bytearray(sec_per_fat * bytes_per_sec)
    fat_data[0] = 0xF0
    fat_data[1] = 0xFF
    fat_data[2] = 0xFF
    fat_data[3] = 0xFF  # cluster 1 EOF marker

    cluster = 2
    for name, content in FILES.items():
        short_name = name.split(".")[0].ljust(8)[:8].upper()
        ext = name.split(".")[1].ljust(3)[:3].upper()
        entry = bytearray(32)
        entry[0:8] = short_name.encode()
        entry[8:11] = ext.encode()
        entry[11] = 0x20  # archive
        struct.pack_into("<H", entry, 26, cluster)
        entry[28:32] = struct.pack("<I", len(content))

        # Write entry to root directory
        root_offset = (reserved_sec + fat_count * sec_per_fat) * bytes_per_sec
        entries = list(FILES.keys()).index(name)
        dir_offset = root_offset + entries * 32
        image[dir_offset:dir_offset+32] = entry

        # Write content to data area
        data_offset = (first_data_sec + (cluster - 2) * sec_per_cluster) * bytes_per_sec
        image[data_offset:data_offset+len(content)] = content

        # Mark cluster as EOF in FAT
        fat_off = cluster * 3 // 2
        fat_word = struct.unpack_from("<H", fat_data, fat_off)[0]
        if cluster & 1:
            fat_word = (fat_word & 0x000F) | (0xFFF << 4)
        else:
            fat_word = (fat_word & 0xF000) | 0x0FFF
        struct.pack_into("<H", fat_data, fat_off, fat_word)

        cluster += 1

    # Write FATs
    for i in range(fat_count):
        off = fat_offset + i * sec_per_fat * bytes_per_sec
        image[off:off+len(fat_data)] = fat_data

    # Boot sector signature at sector 0
    image[510] = 0x55
    image[511] = 0xAA

    os.makedirs(os.path.dirname(outfile) or ".", exist_ok=True)
    with open(outfile, "wb") as f:
        f.write(image)
    print(f"[FAT] Python: {outfile} ({len(image)} bytes)")

if __name__ == "__main__":
    build_fat12_python(OUTPUT)
