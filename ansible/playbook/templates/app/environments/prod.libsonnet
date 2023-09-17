local base = import './base.libsonnet';

base {
  namespace: "prod",
  frontend +: {
    port: 9002,
    ext_port: {{ hostvars[groups.kube_master.0].app_port.prod }},
    replicas: 6,
    requests: {
      cpu: "250m",
      memory: "128Mi"
    }
  }
}
