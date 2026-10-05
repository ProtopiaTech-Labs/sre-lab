# Astronomy Shop — SRE lab

A microservice web shop (based on the [OpenTelemetry Demo](https://github.com/open-telemetry/opentelemetry-demo) 2.1)
running on Kubernetes and fully instrumented: traces, metrics, logs and continuous profiles
go to a shared Grafana stack.

Each participant owns one copy of the shop:

| What | Where |
|---|---|
| Branch | `userN` (deployed on every push) |
| Kubernetes namespace | `userN` |
| Shop | `https://userN-shop.workshop2.indexoutofrange.com` |
| Grafana | `https://grafana.workshop2.indexoutofrange.com`, folder `Uczestnicy/userN/sre-lab` |

## Repository layout

| Path | Content |
|---|---|
| `src/<service>/` | Service code: Go (checkout, product-catalog), .NET (cart), Node.js (payment, frontend), Java (ad), Python (recommendation, load-generator), Rust (shipping), C++ (currency), PHP (quote), Ruby (email) |
| `pb/demo.proto` | gRPC contracts between services |
| `src/flagd/demo.flagd.json` | Feature flags (flagd) |
| `deploy/values.yaml` | Helm values of the shop: configuration, environment variables, resources |
| `deploy/images.yaml` | Images of services not built from this branch |
| `observability/dashboards/` | Dashboards loaded into your Grafana folder |
| `observability/alerts/` | Alert rules loaded into your Grafana folder ([format](observability/alerts/README.md)) |
| `docker-compose.yml`, `.env` | Image build definitions |

## Changing the shop

1. Branch off `userN`, commit, open a pull request into `userN`.
   Only the owner of `userN` can merge into it (check `branch-owner`).
2. Merging deploys (`.github/workflows/deploy.yml`):
   - services whose `src/<service>/` differs from the `lab` baseline are built and pushed
     (`deploy/build.sh`),
   - the Helm chart is installed into namespace `userN` with `deploy/values.yaml`
     (`deploy/deploy.sh`),
   - dashboards and alert rules from `observability/` are loaded into Grafana
     (`deploy/grafana-sync.sh`).
3. Follow the run in Actions → Deploy; the job summary links the shop.

## Telemetry

Every signal carries the namespace:

| Signal | Filter |
|---|---|
| Traces (Tempo) | `{ resource.k8s.namespace.name = "userN" }` |
| Span metrics (RED per service and operation) | `traces_spanmetrics_*{k8s_namespace_name="userN"}` |
| SDK and Kubernetes metrics | `{namespace="userN"}`, SDK metrics also `job="userN/<service>"` |
| Logs (Loki) | `{namespace="userN"}` |
| Profiles (Pyroscope) | `service_name="userN.<service>"` (SDK), `namespace="userN"` (eBPF) |

Data source UIDs: `prometheus`, `loki`, `tempo`, `pyroscope`.
A load generator in the namespace sends steady traffic (browsing, carts, checkouts).
