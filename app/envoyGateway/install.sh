#!/bin/bash
ns="envoy-gateway-system"
helm upgrade --install eg oci://docker.io/envoyproxy/gateway-helm --version "$envoy_version" -n $ns --create-namespace