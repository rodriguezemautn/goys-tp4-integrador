import json
import subprocess
import sys

args = sys.argv[1:]
base = ['k3s', 'kubectl']
payload = sys.stdin.buffer.read() if args == ['-f', '-'] else b''
# Compare resource metadata without logging object bodies.
def execute(verb, extra):
    return subprocess.run(base + [verb] + args + extra, input=payload, capture_output=True, check=True).stdout
def snapshot():
    raw = execute('get', ['--ignore-not-found', '-o', 'json'])
    if not raw.strip():
        return {}
    doc = json.loads(raw)
    return {(x['kind'], x['metadata'].get('namespace'), x['metadata']['name']): (x['metadata']['uid'], x['metadata']['resourceVersion'])
            for x in doc.get('items', [doc])}
try:
    before = snapshot()
    execute('apply', [])
    after = snapshot()
    if not after or before.keys() - after.keys():
        raise ValueError('incomplete snapshot')
except (subprocess.CalledProcessError, ValueError, KeyError) as exc:
    sys.exit(f'Kubernetes apply verification failed ({type(exc).__name__})')
print('changed' if before != after else 'unchanged')
