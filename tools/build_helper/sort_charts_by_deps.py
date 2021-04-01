#!/usr/bin/python

# Script to sort charts for rebuild in order of resolved dependencies
# Use to rebuild charts with dependencies only after rebuilding of their dependencies

import os
import yaml
import argparse

acharts = dict()

def get_yaml(ifl):
    try:
        with open(ifl, "r+") as tx:
            return yaml.safe_load(tx)
    except:
        raise Exception("Failed to load yaml from {}".format(ifl))

def walk_in_deps(ch, dep_rec):
    dns = []
    for dp in dep_rec:
        repo = dp['repository']
        if repo.startswith('file://../'):       # store deps in local repo only
            dns.append(repo.split('/')[-1])
    acharts[ch] = dns

def fill_chart_deps(ch, vfile, rfile):
    rec = get_yaml(vfile)
    acharts[ch] = []
    if 'dependencies' in rec:
        walk_in_deps(ch, rec['dependencies'])
    else:
        if os.path.exists(rfile):
            rec = get_yaml(rfile)
            if 'dependencies' in rec:
                walk_in_deps(ch, rec['dependencies'])

parser = argparse.ArgumentParser()
parser.add_argument("-c", "--charts", help="space-separated list of charts", required=True, nargs='+')
args = parser.parse_args()

for ch in args.charts:
    vfile = os.path.join(ch, 'Chart.yaml')
    rfile = os.path.join(ch, 'requirements.yaml')
    if os.path.exists(vfile):
        fill_chart_deps(ch, vfile, rfile)
    else:
        raise Exception("Expect file {} is not found".format(vfile))

for ch in acharts.keys():
    extra_check = list(set(acharts[ch]) - set(acharts.keys()))
    if extra_check:
        raise Exception("Extra, non-referred local chart deps {} in '{}'".format(extra_check, ch))

rs = []
while bool(acharts):
    for ch in sorted(acharts.keys()):
        if len(acharts[ch]) == 0:                           # collect and exclude charts without deps
            rs.append(ch)
            del acharts[ch]
    for ch in acharts.keys():
        acharts[ch] = list(set(acharts[ch]) - set(rs))      # remove processed from remained charts

print(" ".join(rs))
