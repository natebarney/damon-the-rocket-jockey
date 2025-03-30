#!/usr/bin/env python3

import logging
import os
import struct

def process(infp, outfp):

    riff = infp.read(4)
    if (riff != b"RIFF"):
        raise ValueError("bad RIFF chunk label")

    infp.seek(4, os.SEEK_CUR)

    wave = infp.read(4)
    if (wave != b"WAVE"):
        raise ValueError("bad WAVE chunk label")

    chunks = {}

    while True:

        chunk_name = infp.read(4)
        if len(chunk_name) < 4:
            break

        chunk_size = struct.unpack("<I", infp.read(4))[0]
        chunks[chunk_name.decode("ascii")] = (chunk_size, infp.tell())
        infp.seek(chunk_size, os.SEEK_CUR)

    size, offset = chunks["fmt "]
    infp.seek(offset + 4, os.SEEK_SET)
    sample_rate = struct.unpack("<I", infp.read(4))[0]
    logging.info("Sample Rate: %u", sample_rate)

    size, offset = chunks["data"]
    infp.seek(offset, os.SEEK_SET)
    data = [x - 127 for x in infp.read(size)]
    data = bytes([struct.unpack("B", struct.pack("b", x))[0] for x in data])

    outfp.write(data)


if __name__ == "__main__":

    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("input")
    parser.add_argument("output")
    args = parser.parse_args()

    logging.basicConfig(level=logging.WARNING)

    with open(args.input, "rb") as infp:
        with open(args.output, "wb") as outfp:
            process(infp, outfp)
