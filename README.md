# K8S Node Tasker
A daemonset that peforms a new task on each node when its configmap updates

## Overview

## How does it work
1. node-tasker pod checks every 2 seconds if configmap is updated
1. once node-tasker detects configmap has changed, it then runs a job locally to execute the commands in that configmap
1. node-tasker delete the job once it is complete

## Guide
Create Rbac credentials
```
$ kubectl apply -f rbac.yaml
```
Create node-tasker daemonset
```
$ kubectl apply -f node-tasker.yaml
```
Update configmap with
```
$ kubectl delete cm node-tasker && \
  kubectl create cm node-tasker --from-file=task=hello.sh
```
> It might take serveral minutes Kubernetes propagate configmap updates into the pods. 

## Sequency of execution

1. node-tasker detects configmap updates, and then exit main loop

```
NAME                READY   STATUS              RESTARTS   AGE   IP              NODE
node-tasker-dvhqr   0/1     Completed           0          19m   172.28.230.13   k8s-worker-1
```

2. node-tasker restarts
```
NAME                READY   STATUS              RESTARTS   AGE   IP              NODE
node-tasker-dvhqr   0/1     CrashLoopBackOff    0          19m   172.28.230.13   k8s-worker-1

NAME                READY   STATUS              RESTARTS   AGE   IP              NODE
node-tasker-dvhqr   1/1     Running             1          20m   172.28.230.13   k8s-worker-1
```

3. node-tasker runs a job locally
```
NAME                      READY   STATUS              RESTARTS   AGE   IP              NODE
node-tasker-dvhqr         1/1     Running             1          20m   172.28.230.13   k8s-worker-1
node-tasker-dvhqr-cljdj   0/1     ContainerCreating   0          1s    <none>          k8s-worker-1
```

4. node-tasker deletes the job after it completes
```
NAME                      READY   STATUS              RESTARTS   AGE   IP              NODE
node-tasker-dvhqr         1/1     Running             1         20m   172.28.230.13   k8s-worker-1
node-tasker-dvhqr-cljdj   0/1     Completed           0          3s    172.28.230.22   k8s-worker-1
```

```
NAME                      READY   STATUS              RESTARTS   AGE   IP              NODE
node-tasker-dvhqr         1/1     Running             1         20m   172.28.230.13   k8s-worker-1
```
