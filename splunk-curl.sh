curl http://splunk.openshift.training:8088/services/collector -H 'Authorization: Splunk 6e0e9ccc-e184-46db-a5c4-39fe653fe528' -d '
{
    "time": 1725155849.116,
    "event": "metric",
    "index": "openshift-metrics",
    "source": "metrics",
    "fields": {
      "_value": 4685824,
      "agent_location": "sno.openshift.training",
      "cluster": "sno.openshift.training",
      "container": "olm-operator",
      "endpoint": "https-metrics",
      "environment": "Production",
      "event": "metric",
      "instance": "10.128.0.27:8443",
      "job": "olm-operator-metrics",
      "metric_name": "prometheus.go_memstats_stack_inuse_bytes_3",
      "namespace": "openshift-operator-lifecycle-manager",
      "pod": "olm-operator-769f46dc68-nphj4",
      "prometheus": "openshift-monitoring/k8s",
      "prometheus_replica": "prometheus-k8s-0",
      "service": "olm-operator-metrics",
      "sourcetype": "prometheus"
    }
  }'
