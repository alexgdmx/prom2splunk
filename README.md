# Openshift Prometheus data to Splunk
## Using Prometheus remoteWrite and Telegraf to send data to Splunk HEC.

The Remote-Write protocol is designed to make it possible to reliably propagate samples in real-time from a sender to a receiver, without loss. 

The Remote-Write protocol uses protocol buffers and snnapy.

Protocol Buffers are language-neutral, platform-neutral extensible mechanisms for serializing structured data. 

Snappy is a compression/decompression library. It does not aim for maximum compression, or compatibility with any other compression library; instead, it aims for very high speeds and reasonable compression.

Telegraf collects and sends time series data from databases, systems, and IoT sensors. It has no external dependencies, is easy to install, and requires minimal hardware resources

#### Remote-Write configuration parameters
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

[cluster-monitoring-config.yaml](./cluster-monitoring-config.yaml)
```
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


* Documents
https://prometheus.io/docs/specs/remote_write_spec/
https://protobuf.dev/
https://github.com/google/snappy