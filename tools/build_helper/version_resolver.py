#!/usr/bin/python

# Script to insert image tag or version in charts before builds
# Needs version_slice file for processing

import glob
import json
import argparse

RFW_THIS_LINE_FLAG = "# rfw-update-this"
RFW_NEXT_LINE_FLAG = "# rfw-update-next"

artmap = dict()

def update_line(line, marker_text):
    idx = None
    # determine idx (index string to artmap key)
    if marker_text:
        (_, idx) = marker_text.split(RFW_NEXT_LINE_FLAG, 1)
    else:
        (_, idx) = line.split(RFW_THIS_LINE_FLAG, 1)

    # split incoming line into key, value and comment that should be saved
    left, right = line.split(":", 1)
    rparts = right.split("#", 1)

    # index can point to subkey, if not assume 'version'. then get replacement value
    artid, akey = idx.split(',') if ',' in idx else (idx, 'version')
    new_val = artmap[artid.strip()][akey.strip()]

    # restore comment part if it was present
    rcomment = " #" + rparts[1] if len(rparts) > 1 else '\n'

    return "{}: {}{}".format(left, new_val, rcomment)

def load_artifacts(input_file):
    with open(input_file, "r+") as ijs:
        slice = json.load(ijs)
        for art in slice.get('resolvedArtifacts'):
            if 'artifactId' in art:
                artmap[art['artifactId']] = art
        for comp in slice["resolvedComponentVersions"].keys():
            compid = "*comp*" + comp
            artmap[compid] = slice["resolvedComponentVersions"][comp]

def process_yaml(input_yaml, return_modified=False):
    with open(input_yaml, "r+") as iym:
        ylines = iym.readlines()

    oylines = ylines.copy()
    proc_next = None

    # process line by line and support update of 'next' line
    for yi, tx in enumerate(ylines):
        if RFW_THIS_LINE_FLAG in tx or proc_next:
            ylines[yi] = update_line(tx, proc_next)
            proc_next = None
        elif RFW_NEXT_LINE_FLAG in tx:
            proc_next = tx

    if return_modified:
        return "".join(ylines)

    if oylines != ylines:
        open(input_yaml,'w').write("".join(ylines))


if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument("-vs", "--version-slice", help="path to version_slice file", required=True)
    parser.add_argument("-wd", "--working-dir", help="path to directory, default is ./", default='.')
    args = parser.parse_args()

    load_artifacts(args.version_slice)

    for fl in glob.glob(args.working_dir + '/*/*.yaml', recursive=False):
        process_yaml(fl)
