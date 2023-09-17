local base = import './base.libsonnet';

base {
  namespace: "stage",
  frontend +: {
    port: 9001,
    ext_port: {{ hostvars[groups.kube_master.0].app_port.stage }},
    replicas: 4
  }
}
