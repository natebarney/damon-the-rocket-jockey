#!/usr/bin/env python3

import os.path
import re
import sys

RE_INCLUDE = re.compile(r'^\s*\.INCLUDE\s*"([^"]+)".*$', re.IGNORECASE)

def get_direct_deps(source, search_path=None):
    source = os.path.abspath(source)
    source_dir = os.path.dirname(source)
    if search_path is None:
        search_path = []
    search_path.insert(0, source_dir)

    deps = set()

    with open(source, "r") as fp:
        for line in fp.readlines():
            m = RE_INCLUDE.match(line)
            if m:
                dep = m.group(1)
                found = False
                for incdir in search_path:
                    incdir = os.path.abspath(incdir)
                    candidate = os.path.join(incdir, dep)
                    if os.path.exists(candidate):
                        deps.add(candidate)
                        found = True
                        break
                if not found:
                    deps.add(os.path.join(source_dir, dep))

    return deps

def get_deps(source, search_path=None):
    source = os.path.abspath(source)
    source_dir = os.path.dirname(source)
    done = set()
    todo = [source]
    deps = set()

    while todo:
        file = todo.pop(0)
        if file in done:
            continue
        subdeps = get_direct_deps(file, search_path)
        todo.extend(subdeps)
        deps.update(subdeps)

    if source in deps:
        deps.remove(source)

    deps = [source] + list(sorted(deps))
    deps = [os.path.relpath(dep, source_dir) for dep in deps]
    return deps

def main(inputs, output, search_path):

    if output is None:
        fp = sys.stdout
    else:
        fp = open(output, "w")

    for input in inputs:
        deps = get_deps(input, search_path)
        name, ext = os.path.splitext(input)
        object = name + ".o"
        print(f"{object}: {' '.join(deps)}", file=fp)

    if output is not None:
        fp.close()

if __name__ == "__main__":

    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("input", nargs="+")
    parser.add_argument("-o", dest="output", nargs="?")
    parser.add_argument("-I", action="append", dest="incdirs")
    args = parser.parse_args()

    main(args.input, args.output, args.incdirs)
