{
  release: "r1",
  chart: "apiserver",
  frontend: {
    resources: {}
  },
  images: {
    frontend: "docker.io/artemshtepa/apiserver",
    pullPolicy: "IfNotPresent"
  },
  components: {
  }
}
