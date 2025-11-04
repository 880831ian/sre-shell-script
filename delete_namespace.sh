#! /bin/bash

kubectl proxy --port 8080 &
kubectl get ns ${1} -o json | jq '.spec.finalizers = []' >temp.json
curl -H "Content-Type: application/json" \
    -X PUT \
    --data-binary @temp.json \
    http://127.0.0.1:8080/api/v1/namespaces/${1}/finalize
rm temp.json
kill %1
