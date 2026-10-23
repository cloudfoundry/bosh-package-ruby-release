import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]


class SourceInputsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.pipeline = json.loads(subprocess.check_output(
            ['ytt', '-f', 'ci/pipeline.yml', '-f', 'ci/versions.yml', '-o', 'json'], cwd=REPO))
        cls.resources = {resource['name']: resource for resource in cls.pipeline['resources']}

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='ruby-source-inputs-')
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.bin = self.directory / 'bin'
        self.bin.mkdir()
        self.env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ['PATH'])
        self.tool('curl', '''#!/usr/bin/env python3
import json, os, pathlib, sys
args = sys.argv[1:]
if any('api.github.com' in arg for arg in args):
    print(json.dumps({'assets': [{'name': 'rubygems-'+os.environ['version']+'.tgz', 'digest': os.environ.get('FIXTURE_DIGEST')}]}))
elif '--head' in args:
    print('Content-Length: 123')
else:
    data = pathlib.Path(os.environ['FIXTURE_BYTES']).read_bytes()
    if '--output' in args:
        pathlib.Path(args[args.index('--output')+1]).write_bytes(data)
    else:
        sys.stdout.buffer.write(data)
''')

    def tool(self, name, script):
        path = self.bin / name
        path.write_text(script)
        path.chmod(0o755)

    def metalink(self, resource, version, digest='sha256:' + 'a' * 64):
        env = dict(self.env, version=version)
        if digest is not None:
            env['FIXTURE_DIGEST'] = digest
        return subprocess.run(['bash', '-c', self.resources[resource]['source']['metalink_get']],
                              env=env, text=True, capture_output=True)

    def test_rubygems_publishes_official_asset_digest(self):
        result = self.metalink('rubygems-3.5', '3.5.23')
        self.assertEqual(result.returncode, 0, result.stderr)
        file = json.loads(result.stdout)['files'][0]
        self.assertEqual(file['hashes'], [{'type': 'sha-256', 'hash': 'a' * 64}])
        self.assertTrue(file['urls'][0]['url'].startswith('https://rubygems.org/'))

    def test_rubygems_rejects_missing_or_invalid_digest(self):
        for digest in [None, '', 'null', 'sha256:abc', 'md5:' + 'a' * 32]:
            with self.subTest(digest=digest):
                result = self.metalink('rubygems-3.5', '3.5.23', digest)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(result.stdout, '')

    def test_libyaml_requires_reviewed_version_digest(self):
        result = self.metalink('yaml-0.2', '0.2.5')
        self.assertEqual(result.returncode, 0, result.stderr)
        file = json.loads(result.stdout)['files'][0]
        self.assertEqual(file['hashes'][0]['hash'], 'c642ae9b75fee120b2d96c712538bd2cf283228d2337df2cf2988e3c02678ef4')
        self.assertTrue(file['urls'][0]['url'].startswith('https://github.com/yaml/libyaml/'))
        unknown = self.metalink('yaml-0.2', '0.2.99')
        self.assertNotEqual(unknown.returncode, 0)
        self.assertEqual(unknown.stdout, '')

    def cli_run(self, supplied_hash, data):
        dockerfile = (REPO / 'ci/docker/Dockerfile').read_text()
        command = re.search(r'^RUN ((?:test -n|curl -sL).*?)(?=\n\n)', dockerfile, re.M | re.S).group(1)
        target = self.directory / 'bosh'
        command = command.replace('/usr/bin/bosh', str(target))
        source = self.directory / 'fixture'
        source.write_bytes(data)
        marker = self.directory / 'executable'
        marker.unlink(missing_ok=True)
        self.tool('chmod', '#!/usr/bin/env bash\nprintf executed > "$FIXTURE_CHMOD_MARKER"\n')
        self.tool('sha256sum', '#!/usr/bin/env bash\nexec shasum -a 256 "$@"\n')
        return subprocess.run(['bash', '-c', command], capture_output=True, text=True,
                              env=dict(self.env, BOSH_CLI_VERSION='7.11.2', BOSH_CLI_SHA256=supplied_hash,
                                       FIXTURE_BYTES=str(source), FIXTURE_CHMOD_MARKER=str(marker))), marker

    def test_cli_archive_verified_before_making_executable(self):
        good = b'fixture-cli-bytes'
        expected = hashlib.sha256(good).hexdigest()
        result, marker = self.cli_run(expected, good)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(marker.exists())
        result, marker = self.cli_run(expected, b'tampered-cli-bytes')
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(marker.exists())
        result, marker = self.cli_run('', good)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(marker.exists())

    def test_pipeline_passes_pinned_cli_version_and_hash_together(self):
        job = next(job for job in self.pipeline['jobs'] if job['name'] == 'build-docker-image')
        task = next(step for step in job['plan'] if step.get('task') == 'build-oci-image')
        params = task['config']['params']
        self.assertEqual(params['BUILD_ARG_BOSH_CLI_VERSION'], '7.11.2')
        self.assertEqual(params['BUILD_ARG_BOSH_CLI_SHA256'], '839a92403901639e0e1f3130e4138c912bfd217bd1579277048fcd6bf5dee28c')


if __name__ == '__main__':
    unittest.main()
