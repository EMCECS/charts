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
    if marker_text:
        (_, idx) = marker_text.split(RFW_NEXT_LINE_FLAG, 1)
    else:
        (_, idx) = line.split(RFW_THIS_LINE_FLAG, 1)

    left, right = line.split(": ", 1)
    rparts = right.split("#", 1)

    artid, akey = idx.split(',') if ',' in idx else (idx, 'version')
    new_val = artmap[artid.strip()][akey.strip()]

    rcomment = " #" + rparts[1] if len(rparts) > 1 else '\n'

    return "{}: {}{}".format(left, new_val, rcomment)

def load_artifacts(input_file):
    with open(input_file, "r+") as ijs:
        slice = json.load(ijs)
        for art in slice.get('resolvedArtifacts'):
            if 'artifactId' in art:
                artmap[art['artifactId']] = art

def process_yaml(input_yaml):
    with open(input_yaml, "r+") as iym:
        ylines = iym.readlines()

    oylines = ylines.copy()
    proc_next = None
    for yi, tx in enumerate(ylines):
        if RFW_THIS_LINE_FLAG in tx or proc_next:
            ylines[yi] = update_line(tx, proc_next)
            proc_next = None
        elif RFW_NEXT_LINE_FLAG in tx:
            proc_next = tx

    if oylines != ylines:
        open(input_yaml + ".proc",'w').write("".join(ylines))


if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument("-vs", "--version-slice", help="path to version_slice file", required=True)
    args = parser.parse_args()

    load_artifacts(args.version_slice)

    for fl in glob.glob('./*/*.yaml', recursive=False):
        process_yaml(fl)
