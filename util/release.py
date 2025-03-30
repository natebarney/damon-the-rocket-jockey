#!/usr/bin/python3

import json
from zipfile import ZipFile, ZIP_DEFLATED

PRG_FILENAME = "DAMON.PRG"

def make_release(version: str, prg_file: str, extra_files: [str]):

    manifest = {
        "manifest_version": "1.0.0",
        "name": "Damon: The Rocket Jockey",
        "author": "Nate Barney",
        "app_version": version,
        "start_prg": PRG_FILENAME,
        "resources": [
            PRG_FILENAME,
        ]
    }

    for extra_file in extra_files:
        extra_file = extra_file.upper()
        manifest["resources"].append(extra_file)

    manifest_data = (json.dumps(manifest, indent=2) + "\n").encode("utf8")

    with ZipFile(f"damon-{version}.zip", "w", ZIP_DEFLATED) as zipfp:

        with zipfp.open("manifest.json", "w") as fp:
            fp.write(manifest_data)

        with open(prg_file, "rb") as fp:
            data = fp.read()

        with zipfp.open(PRG_FILENAME, "w") as fp:
            fp.write(data)

        for extra_file in extra_files:
            with open(extra_file, "rb") as fp:
                data = fp.read()
            with zipfp.open(extra_file.upper(), "w") as fp:
                fp.write(data)

if __name__ == "__main__":

    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("version")
    parser.add_argument("prg_file")
    parser.add_argument("extra_file", nargs="*")
    args = parser.parse_args()

    make_release(args.version, args.prg_file, args.extra_file)
