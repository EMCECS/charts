import unittest
import json
import sys
import os

class TestVersionResolver(unittest.TestCase):

    cur_dir = os.path.dirname(os.path.realpath(__file__))

    @classmethod
    def setUpClass(cls):
        sys.path.append(os.path.join(TestVersionResolver.cur_dir, ".."))

    def test_version_resolver(self):
        import version_resolver as vr

        inp_vs = os.path.join(TestVersionResolver.cur_dir, "test_vs.json")
        vr.load_artifacts(inp_vs)

        for nf in ('test_vs_chart.yaml', 'test_vs_values.yaml'):
            nf = os.path.join(TestVersionResolver.cur_dir, nf)
            mod_yml = vr.process_yaml(nf, return_modified=True)
            expectedf = nf + ".expected"
            with open(expectedf, "r+") as iym:
                expected_tx = iym.read()

            if mod_yml != expectedf:
                modf = nf + ".modified"
                with open(modf, "w") as wym:
                    wym.write(mod_yml)

            assert False, "Wrong modified content, see file {}, expected in {}" \
                          .format(modf, expectedf)


if __name__ == "__main__":
   unittest.main()
