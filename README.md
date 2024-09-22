# Openshift Prometheus data to Splunk
## Using Prometheus remoteWrite and Telegraf to send data to Splunk HEC. for s390x architecture

The Remote-Write protocol is designed to make it possible to reliably propagate samples in real-time from a sender to a receiver, without loss. 

The Remote-Write protocol uses protocol buffers and snnapy.

Protocol Buffers are language-neutral, platform-neutral extensible mechanisms for serializing structured data. 

Snappy is a compression/decompression library. It does not aim for maximum compression, or compatibility with any other compression library; instead, it aims for very high speeds and reasonable compression.

Telegraf collects and sends time series data from databases, systems, and IoT sensors. It has no external dependencies, is easy to install, and requires minimal hardware resources.

Almost every product for metric/data collection works in 3 stages
| --> Input  | Proccesing --> | Output --> |
| :---------------- | :------: | ----: |



Evaluation of 3 known technologies
| Product  | Input remoteWrite | Output Splunk | Output Dynatrace |  s390x |
| :------- | :---------------: | :-----------: | :--------------: | :----: |
| LogStash | False | False | True | ❌ |
| Vektor | True | True | True | ❌ |
| Telegraf | True | True | True | ✅ s/c |


## Configure Prometeus and Telegraf
### Remote-Write configuration parameters
```bash
[alex@bastion ~]$ oc explain prometheus.spec.remoteWrite
GROUP:      monitoring.coreos.com
KIND:       Prometheus
VERSION:    v1

FIELD: remoteWrite <[]Object>

DESCRIPTION:
    Defines the list of remote write configurations. RemoteWriteSpec defines the configuration to write samples from Prometheus to a remote endpoint.

FIELDS:
  authorization	        <Object>
  azureAd               <Object>
  basicAuth             <Object>
  bearerToken           <string>
  bearerTokenFile       <string>
  enableHTTP2	        <boolean>
  headers               <map[string]string>
  metadataConfig        <Object>
  name	                <string>
  oauth2                <Object>
  proxyUrl              <string>
  queueConfig           <Object>
  remoteTimeout	        <string>
  sendExemplars	        <boolean>
  sendNativeHistograms	<boolean>
  sigv4	                <Object>
  tlsConfig         	<Object>
  url	                <string> -required-
  writeRelabelConfigs	<[]Object>
```

- [cluster-monitoring-config.yaml](./cluster-monitoring-config.yaml)
  ```yaml
    prometheusK8s:
      externalLabels:
        agent_location: sno.openshift.training
        environment: Production
        event: metric
        source: metrics
      retention: 7d
      remoteWrite:
        - url: "http://telegraf:1234/receive"
  ```
### Telegraf configuration
- [telegraf configuration](./telegraf-configmap-splunk.yaml)
  ```yaml
    [[inputs.http_listener_v2]]
      service_address = ":1234"
      paths = ["/receive"]
      data_format = "prometheusremotewrite"

    [[processors.starlark]]
      source = '''
    def apply(metric):
      if metric.name == "prometheus_remote_write":
        for k, v in metric.fields.items():
          # metric.name = k
          metric.name = 'prometheus'
          # metric.fields["value"] = v
          # metric.fields.pop(k)
      return metric
    '''

    [[outputs.http]]
      url = "$SPLUNK_URL"
      data_format = "splunkmetric"
      splunkmetric_hec_routing = true
      # splunkmetric_multimetric = true
      # splunkmetric_omit_event_tag = true
      [outputs.http.headers]
        Content-Type = "application/json"
        Authorization = "Splunk $SPLUNK_TOKEN"
  ```

## Secure components
### Securing service traffic using service serving certificate secrets

We are usign Telegraf as kubernetes service, we will use OpenShift to secure service traffic using ```service.beta.openshift.io/serving-cert-secret-name: true``` annotation.

```yaml
metadata:
  annotations:
    service.beta.openshift.io/serving-cert-secret-name: telegraf-service-tls 
```

We need to create an empty configMap with the annotation ```service.beta.openshift.io/inject-cabundle``` to store the CA.
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  annotations:
    service.beta.openshift.io/inject-cabundle: "true"
  name: telegraf-ca-cert
  namespace: openshift-monitoring
data: {}
```

This will create a secret with the certificate and the key, and the configMap with the CA that we can use to mount as volumnes or env variables in our deployment.

### Securing Deployment
```yaml
      volumes:
        - name: telegraf-config
          configMap:
            name: telegraf-config
        - name: telegraf-ca-cert
          configMap:
            name: telegraf-ca-cert
        - name: service-secret-tls
          secret:
            secretName: telegraf-service-tls 
```
### Adding certificates to Telegraf
```yaml
    [[inputs.http_listener_v2]]
      service_address = ":1234"
      paths = ["/receive"]
      data_format = "prometheusremotewrite"
      tls_cert = "/etc/telegraf/tls/tls.crt"
      tls_key = "/etc/telegraf/tls/tls.key"
```
### Add configuration to Prometheus remoteWrite
```yaml
      remoteWrite:
        - url: "https://telegraf.openshift-monitoring.svc:1234/receive"
          tlsConfig:
            ca:
              configMap:
                name: telegraf-ca-cert
                key: service-ca.crt
            cert:
              secret:
                name: telegraf-service-tls 
                key: tls.crt 
            keySecret:
              name: telegraf-service-tls 
              key: tls.key

```

Bibliografy
https://prometheus.io/docs/specs/remote_write_spec/
https://protobuf.dev/
https://github.com/google/snappy
https://www.influxdata.com/time-series-platform/telegraf/
https://docs.openshift.com/container-platform/4.16/security/certificates/service-serving-certificate.html