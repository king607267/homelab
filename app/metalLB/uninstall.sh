#!/bin/bash
ns="metallb-system"
if helm status metallb -n $ns >/dev/null 2>&1; then
  helm delete metallb -n $ns
fi