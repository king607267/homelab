#!/bin/bash
ns="monitoring"
chart_name="prome-stack"
if helm status $chart_name -n $ns >/dev/null 2>&1; then
  helm delete $chart_name -n $ns
fi