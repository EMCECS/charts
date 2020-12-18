#!/usr/bin/python

# this script is used to compose json file for wiki page
# with auto-generated alerts report
#
# workflow:
# 1. run makefile template-all
# 2. python this.py path/to/template_all.yaml output.json
# 3. public output.json
# 4. setup wiki tables to read URL 

import sys
import json
import time
import yaml
import logging

srec = dict()

def get_config_maps(ifl):
    with open(ifl, "r+") as f:
        all_data = f.read()

    cmds = []

    for elm in all_data.split('---'):
        if not 'name' in elm and not 'ConfigMap' in elm:
            continue
        if not ('eventRules' in elm or 'eventRemedies' in elm):
            continue

        try:
            el = yaml.safe_load(elm)
        except:
            logging.info("Can't parse ...")
            continue

        if el['kind'] == 'ConfigMap':
            cmds.append(el)

    return cmds

def parse_rules(tx):
    try:
        dt = yaml.safe_load(tx)
    except:
        logging.info("Can't parse ...")

    if not dt:
        return

    if 'issueRules' in dt:
        for ir in dt['issueRules']:
            for ml in ir['matchOnList']:
                for mh in ml['matchon']:
                    if mh['label'] == 'SymptomID':
                        reg_rule(mh['value'], ir.copy())
                    else:
                        raise Exception("Unknown match label {}".format(tx))

    if 'rules' in dt:
        for rl in dt['rules']:
            for mh in rl['matchon']:
                if mh['label'] == 'SymptomID':
                    reg_rule(mh['value'], rl.copy())
                else:
                    raise Exception("Unknown match label {}".format(tx))

def reg_rule(sim, ir):
    if not sim in srec:
        srec[sim] = dict()

    for kr in ('matchOnList', 'matchon'):
        if kr in ir:
            del ir[kr]

    srec[sim] = ir

def parse_remedies(tx):
    try:
        dt = yaml.safe_load(tx)
    except:
        logging.info("Can't parse ...")

    if not dt:
        return

    for sm in dt['symptoms']:
        sim = sm['symptomid']
        rmd = sm['remedies']

        if not sim in srec:
            srec[sim] = dict()
        srec[sim]['remedies'] = rmd
        if 'description' in sm and not 'description' in srec[sim]:
            srec[sim]['description'] = sm['description']

def remap_for_json():
    js = []
    for sim in sorted(srec.keys()):
        rc = { 'SymptomId': sim }
        for sk in srec[sim].keys():
            vv = srec[sim][sk]
            if type(vv) is list:
                vv = ", ".join(vv)
            rc[sk] = vv

        # compress something
        if 'defaultAutoClearTimeOut' in rc and 'issueCategory' in rc:
            rc['issueCategory'] += ', ' + str(rc['defaultAutoClearTimeOut'])
            del rc['defaultAutoClearTimeOut']

        js.append(rc)
    return {
                'issues': js,
                'metadata': [
                                {'Generation Time-stamp': time.strftime('%X %x %Z')}
                            ]
    }

if len(sys.argv[1]) < 3:
    raise Exception("specify all-yaml output files in argument")

cms = get_config_maps(sys.argv[1])
for cm in cms:
    #print cm['metadata']['name']
    if 'eventRules' in cm['data']:
        parse_rules(cm['data']['eventRules'])
    if 'eventRemedies' in cm['data']:
        parse_remedies(cm['data']['eventRemedies'])
        #print cm['data']['']

jdata = remap_for_json()

jtx = json.dumps(jdata, indent=4, sort_keys=True)
with open(sys.argv[2], "w") as of:
    of.write(jtx)

confluence_page_source = """

<p class="auto-cursor-target">Generated at:</p>
<ac:structured-macro ac:macro-id="X1" ac:name="json-table" ac:schema-version="1">
  <ac:parameter ac:name="sortColumn">SymptomId</ac:parameter>
  <ac:parameter ac:name="paths">metadata</ac:parameter>
  <ac:parameter ac:name="url">X2</ac:parameter>
  <ac:parameter ac:name="sortIcon">true</ac:parameter>
</ac:structured-macro>
<p>Issues:</p>
<ac:structured-macro ac:macro-id="X3" ac:name="json-table" ac:schema-version="1">
  <ac:parameter ac:name="output">wiki</ac:parameter>
  <ac:parameter ac:name="sortColumn">SymptomId</ac:parameter>
  <ac:parameter ac:name="columns">SymptomId,name,description,issueCategory,notifiers,remedies</ac:parameter>
  <ac:parameter ac:name="paths">issues</ac:parameter>
  <ac:parameter ac:name="url">X4</ac:parameter>
  <ac:parameter ac:name="augments">[%SymptomId%|Alert %SymptomId%],,,,,</ac:parameter>
</ac:structured-macro>

"""

