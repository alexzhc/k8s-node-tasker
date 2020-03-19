#!/bin/sh -x

# Force delete jobs (for preStop cleanup)
[ "$1" = "--cleanup-only" ] && kubectl delete --grace-period 0 --force job "$THIS_POD_NAME" && exit 0 

# Clean up completed jobs
_cleanup_completed_job(){
[ -n "$( kubectl -n "$THIS_POD_NAMESPACE" \
    get pod -l app.kubernetes.io/component="$THIS_POD_NAME" \
    --field-selector=status.phase=Succeeded )" ] &&
    kubectl delete job "$THIS_POD_NAME"
}

_cleanup_completed_job

# Create a new job if /var/local/run/task exists
if [ -s /var/local/run/task ]; then
    cat /job.yaml \
    | sed "s/namespace: default/namespace: ${THIS_POD_NAMESPACE}/" \
    | sed "s/- localhost/- ${THIS_NODE_NAME}/" \
    | sed "s/ node-tasker-job/ ${THIS_POD_NAME}/" \
    | sed "s#image: busybox#image: ${JOB_IMG}#" \
    | kubectl apply -f - 
fi

# Check if configmap gets updated, restart if updated
trap 'exit 0' SIGTERM SIGINT
previous_checksum="$( sha256sum /var/local/run/task )"
while sleep 2; do
    current_checksum="$( sha256sum /var/local/run/task )"
    _cleanup_completed_job
    [ "$current_checksum" != "$previous_checksum" ] && echo "* New task arrived!" && exit 0
done