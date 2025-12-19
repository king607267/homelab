#!/bin/bash
ns="cilium"
if helm status cilium -n $ns >/dev/null 2>&1; then
  helm delete cilium -n $ns
fi