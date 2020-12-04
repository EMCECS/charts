#Dell EMC Federation Service  Helm Chart

This Helm chart deploys a Dell EMC Federation Service and its dependencies.

## Table of Contents

* [Description](#description)

## Description

The Dell EMC Federation Service for the secure interaction between Objectscale instance.

By default the federation service feature is not enabled in objectscale-manager.

To enable federation service on the install - include:
```bash
  --set federation.enabled=true
```


