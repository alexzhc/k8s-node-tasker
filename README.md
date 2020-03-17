# K8S Node Tasker
A daemonset that peforms a new task on each node whenever its configmap updates

## Why this project:
Kubernetes does not implement a "daemonset + job" mechanism. This project is meant achieve it with minimal structure. 

## How it works:
1. deploy a daemonset
2. the task script is executed in the initContainer so that it can run into completion;
3. the container runs a main loop that every 2 seconds checks configmap changes by hash code;
4. the main loop exits when detecting configmap change, which causes the pod reinit, thus performing a new task;
