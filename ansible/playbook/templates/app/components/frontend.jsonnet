local p = import '../params.libsonnet';

local r_name = p.release + "-diplom";
local r_chart = p.chart + "-app";
local r_port = p.frontend.port;

[
  {
    apiVersion: "apps/v1",
    kind: "Deployment",
    metadata: {
      labels: {
        app: r_name
      },
      name: r_name,
      namespace: p.namespace
    },
    spec: {
      replicas: std.get(p.frontend, "replicas", default=1),
      selector: {
        matchLabels: {
          app: r_name
        }
      },
      template: {
        metadata: {
          labels: {
            app: r_name
          },
        },
        spec: {
          containers: [
            {
              name: r_chart,
              image: p.images.frontend + ":" + std.extVar("app_image_tag"),
              imagePullPolicy: p.images.pullPolicy,
              env: [
                {
                  name: "API_BIND",
                  value: ":" + std.toString(r_port)
                },
              ],
              ports: [
                {
                  containerPort: r_port,
                  protocol: "TCP"
                }
              ],
              resources: p.frontend.resources,
              readinessProbe: {
                tcpSocket: {
                  port: r_port
                },
                initialDelaySeconds: 10,
                periodSeconds: 10
              },
              livenessProbe: {
                exec: {
                  command: [
                    "curl",
                    "-s",
                    "http://127.0.0.1:" + r_port + "/uuid"
                  ]
                },
                initialDelaySeconds: 10,
                periodSeconds: 10
              }
            }
          ]
        }
      }
    }
  },
  {
    apiVersion: "v1",
    kind: "Service",
    metadata: {
      name: r_name + "-svc",
      namespace: p.namespace
    },
    spec: {
      selector: {
        app: r_name
      },
      type: "NodePort",
      ports: [
        {
          name: r_name + "-port",
          port: r_port,
          nodePort: p.frontend.ext_port,
          protocol: "TCP"
        }
      ]
    }
  }
]
