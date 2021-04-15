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
            expectedf = nf.replace(".yaml", ".expected.yaml")
            with open(expectedf, "r+") as iym:
                expected_tx = iym.read()

            modf = nf + ".modified"
            with open(modf, "w") as wym:
                wym.write(mod_yml)

            assert mod_yml == expected_tx, "Wrong modified content, see file {}, expected in {}" \
                                         .format(modf, expectedf)

            # now test that processing is idempotent, i.e. can be executed multiple time without degradation

            mod_yml2 = vr.process_yaml(modf, return_modified=True)

            if mod_yml2 != expectedf:
                modf2 = nf + ".modified2"
                with open(modf, "w") as wym:
                    wym.write(mod_yml2)

            assert mod_yml2 == expected_tx, "Wrong 2nd-time modified content, see file {}, expected in {}" \
                                         .format(modf2, expectedf)

            # if everything is fine, remove modified file
            os.remove(modf)

if __name__ == "__main__":
   unittest.main()
