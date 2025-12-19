#!/bin/bash
ns="headlamp"
if helm status my-headlamp -n $ns >/dev/null 2>&1; then
  helm delete my-headlamp -n $ns
fi
token=$(pwd)/admin-user-token
if [ -f "$token" ]; then
  rm "$token"
fi