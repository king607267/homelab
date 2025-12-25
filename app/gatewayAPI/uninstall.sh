#!/bin/bash
if helm status home-gateway -n "$gateway_namespace" >/dev/null 2>&1; then
  helm delete home-gateway -n "$gateway_namespace"
fi