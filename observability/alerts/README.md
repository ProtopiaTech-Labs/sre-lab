# Alert rules

Every `*.yaml` file here is loaded into this branch's Grafana folder
(`Uczestnicy/<namespace>/sre-lab`) by the deploy workflow (`deploy/grafana-sync.sh`).
The folder mirrors this directory: rule groups removed from the files are deleted.

Format: Grafana's alert rule export (Alerting → Alert rules → Export → YAML). Per rule:
`uid`, `title`, `condition`, `data`, `for`, `labels`, `annotations`, `noDataState`,
`execErrState`. The sync prefixes each `uid` with the namespace, adds the label
`namespace=<namespace>`, replaces `${NAMESPACE}` anywhere in the file with your namespace,
and ignores the `folder` field of an export.

Data source UIDs: `prometheus`, `loki`, `tempo`. Shop metrics carry the namespace as
`k8s_namespace_name` (span metrics), `namespace` (SDK, kube-state-metrics, cAdvisor)
and `{namespace="..."}` in Loki.

```yaml
apiVersion: 1
groups:
  - name: pods
    interval: 1m
    rules:
      - uid: crashlooping-pods
        title: Containers restarting
        condition: C
        for: 10m
        data:
          - refId: A
            relativeTimeRange: { from: 900, to: 0 }
            datasourceUid: prometheus
            model:
              refId: A
              instant: true
              expr: sum by (pod) (increase(kube_pod_container_status_restarts_total{namespace="${NAMESPACE}"}[15m]))
          - refId: C
            datasourceUid: __expr__
            model:
              refId: C
              type: threshold
              expression: A
              conditions:
                - evaluator: { type: gt, params: [2] }
        labels:
          severity: ticket
        annotations:
          summary: "{{ $labels.pod }} restarted more than twice in 15 minutes"
```
