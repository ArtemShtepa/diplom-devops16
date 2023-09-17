local p = import '../params.libsonnet';

[
  {
    apiVersion: 'v1',
    kind: 'Namespace',
    metadata: {
      name: p.namespace
    }
  }
]
