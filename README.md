# Network UPS Tools for Docker/Kubernetes

This project bundles Network UPS Tools (aka NUT) into an Debian Trixie based docker image. The reason for this is to work around [an issue](https://github.com/networkupstools/nut/issues/2077) I have with Debian's stable builds of NUT where NUT was unable to correctly parse SNMP data from my CyberPower OR1500LCDRT2U UPS via the RMCARD205 management interface.

The image was designed to run in netserver mode and listens on 0.0.0.0 by default

## Usage

### Docker

    ---
    version: "2.1"

    services:
      network-ups-tools:
        image: untouchedwagons/network-ups-tools:1.0.0
        container_name: nut
        ports:
          - 3493:3493
        volumes:
          - ./ups.conf:/etc/nut/ups.conf:ro
          - ./upsd.users:/etc/nut/upsd.users:ro
        restart: unless-stopped

The contents of `ups.conf` would look something like this:

    [nutdev1]
    driver = "snmp-ups"
    port = "192.168.0.135"
    desc = "OR1500LCDRT2U"
    mibs = "cyberpower"
    community = "public"

The contents of `upsd.users` would look something like this:

    [upsmon]
      password = CorrectHorseBatteryStaple
      upsmon slave

While this image was intended to use SNMP it should work just fine using USB and serial.

### Kubernetes

    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: nut
      namespace: networking
    data:
      ups.conf: | # Adjust this section as needed
        [OR1500LCDRT2U]
        driver = "snmp-ups"
        port = "rmcard205.internal.untouchedwagons.com"
        desc = "OR1500LCDRT2U"
        mibs = "cyberpower"
        community = "public"
      upsd.users: | # Adjust this section as needed
        [upsmon]
          password = CorrectHorseBatteryStaple
          upsmon slave
    ---
    kind: Deployment
    apiVersion: apps/v1
    metadata:
      name: nut
      namespace: networking
      labels:
        app: nut
    spec:
      replicas: 3
      progressDeadlineSeconds: 600
      revisionHistoryLimit: 0
      strategy:
        type: Recreate
      selector:
        matchLabels:
          app: nut
      template:
        metadata:
          labels:
            app: nut
        spec:
          containers:
            - name: nut
              image: untouchedwagons/network-ups-tools:1.0.0
              volumeMounts:
                - mountPath: /etc/nut/ups.conf
                  name: nut-config
                  subPath: ups.conf
                - mountPath: /etc/nut/upsd.users
                  name: nut-config
                  subPath: upsd.users
          volumes:
            - name: nut-config
              configMap:
                name: nut
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: nut
      namespace: networking
    spec:
      type: LoadBalancer
      selector:
        app: nut
      ports:
        - name: nut
          targetPort: 3493
          port: 3493

To see what IP to point your NUT clients at run `kubectl describe service -n networking nut` and look at LoadBalancer line.
