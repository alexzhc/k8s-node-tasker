#!/bin/sh -x

# Force delete jobs (for preStop cleanup)
[ "$1" = "--cleanup-only" ] && kubectl delete --grace-period 0 --force job "$THIS_POD_NAME" && exit 0 

# Clean up completed jobs
_cleanup_completed_job(){
for i in "$( kubectl -n "$THIS_POD_NAMESPACE" get pod -l app.kubernetes.io/name=node-tasker --field-selector=status.phase=Succeeded -o name )"; do
    [ -z "$i" ] && continue
    kubectl delete job "$( echo $i | sed -r 's/pod\/(.*)-[a-z0-9]+$/\1/' )"
done
}
_cleanup_completed_job

# Create a new job if /var/local/run/task exists
if [ -s /var/local/run/task ]; then
    cat /job.yaml \
    | sed "s/namespace: default/namespace: ${THIS_POD_NAMESPACE}/" \
    | sed "s/- localhost/- ${THIS_NODE_NAME}/" \
    | sed "s/name: node-tasker-job/name: ${THIS_POD_NAME}/" \
    | kubectl apply -f - 
fi

# Check if configmap gets updated, restart if updated
trap 'exit 0' SIGTERM SIGINT
previous_checksum="$( sha256sum /var/local/run/task )"
while sleep 1; do
    current_checksum="$( sha256sum /var/local/run/task )"
    _cleanup_completed_job
    [ "$current_checksum" != "$previous_checksum" ] && echo "* New task arrived!" && exit 0
done