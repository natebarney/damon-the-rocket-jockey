#!/usr/bin/python3

import json
from zipfile import ZipFile, ZIP_DEFLATED

def make_release(prg_file: str, version: str):

    manifest = {
        "manifest_version": "1.0.0",
        "name": "Damon: The Rocket Jockey",
        "author": "Nate Barney",
        "app_version": version,
        "start_prg": "DAMON.PRG",
        "resources": [
            "DAMON.PRG"
        ]
    }

    manifest_data = (json.dumps(manifest, indent=2) + "\n").encode("utf8")

    with open(prg_file, "rb") as fp:
        prg_data = fp.read()

    with ZipFile(f"damon-{version}.zip", "w", ZIP_DEFLATED) as zipfp:

        with zipfp.open("manifest.json", "w") as fp:
            fp.write(manifest_data)

        with zipfp.open("DAMON.PRG", "w") as fp:
            fp.write(prg_data)

if __name__ == "__main__":

    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("prg_file")
    parser.add_argument("version")
    args = parser.parse_args()

    make_release(args.prg_file, args.version)
