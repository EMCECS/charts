#Dell EMC ObjectScale Gateway Helm Chart

This Helm chart deploys a Dell EMC ObjectScale Gateway

## Table of Contents

* [Description](#description)

## Description

The Dell EMC ObjectScale Gateway for the secure interaction within Objectscale instance and trusted ObjectScale Instance.

By default ObjectScale Gateway feature is disabled in objectscale-manager

To enable ObjectScale Gateway on the install - include:
```bash
--set objectscale-gateway.enabled=true \
--set objectscale-iam.objectscaleGateway.enabled=true \
--set federation.objectscaleGateway.enabled=true 
```




