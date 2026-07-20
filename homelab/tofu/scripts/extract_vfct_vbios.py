#!/usr/bin/env python3

import argparse
import hashlib
import os
import struct
import tempfile
from pathlib import Path

AMD_VENDOR_ID = 0x1002
RADEON_890M_DEVICE_ID = 0x150E
VFCT_IMAGE_OFFSET = 52
VFCT_IMAGE_HEADER_SIZE = 28


def extract_vbios(table: bytes) -> bytes:
    if table[:4] != b'VFCT':
        raise RuntimeError('ACPI VFCT table is unavailable')

    offset = struct.unpack_from('<I', table, VFCT_IMAGE_OFFSET)[0]
    while offset + VFCT_IMAGE_HEADER_SIZE <= len(table):
        header = struct.unpack_from('<IIIHHHHII', table, offset)
        vendor_id, device_id, image_length = header[3], header[4], header[8]
        image_start = offset + VFCT_IMAGE_HEADER_SIZE
        image = table[image_start : image_start + image_length]

        if vendor_id == AMD_VENDOR_ID and device_id == RADEON_890M_DEVICE_ID:
            if len(image) != image_length or image[:2] != b'\x55\xaa' or sum(image) % 256:
                raise RuntimeError('VFCT contains an invalid AMD GPU VBIOS')
            return image

        if image_length == 0:
            break
        offset = image_start + image_length

    raise RuntimeError('AMD Radeon 890M VBIOS is absent from ACPI VFCT')


def write_atomically(path: Path, contents: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(dir=path.parent)
    temporary = Path(temporary_name)

    try:
        with os.fdopen(descriptor, 'wb') as file:
            file.write(contents)
        temporary.chmod(0o644)
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--sha256', required=True)
    parser.add_argument(
        '--vfct',
        type=Path,
        default=Path('/sys/firmware/acpi/tables/VFCT'),
    )
    args = parser.parse_args()

    vbios = extract_vbios(args.vfct.read_bytes())
    actual_checksum = hashlib.sha256(vbios).hexdigest()
    if actual_checksum != args.sha256:
        raise RuntimeError(f'unexpected AMD GPU VBIOS checksum: {actual_checksum}')

    if args.output.exists() and hashlib.sha256(args.output.read_bytes()).hexdigest() == args.sha256:
        return

    write_atomically(args.output, vbios)


if __name__ == '__main__':
    main()
