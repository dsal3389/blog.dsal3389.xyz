---
title: "minikube and k8s"
date: 2022-05-31T17:20:13+03:00
slug: minikube_and_k8s
type: posts
draft: false
categories:
  - k8s
tags:
  - minikube
  - k8s
---

to play with k8s we needed couple of machines or create couple of VMs so we could create a cluster because k8s cant run on a single node as a worker and master,
so the k8s team came up with minikube which is a greate tool that uses a virtual machine technology, it creates a signle node cluster on a virtual machine

## how does it work, hight level
minikube takes a virtual machine technology like [virtual box](https://www.virtualbox.org/) or [VMware](https://www.vmware.com/il/products/workstation-pro.html), create a new virtual machine for the cluste,
configure your _~/.kubectl/config_ to work with the new minikube cluster and thats basiclly it

there are some requirements for minikube VM you can look the minimum requirements here:
* [what-youll-need](https://minikube.sigs.k8s.io/docs/start/#what-youll-need)
* and ofcourse VMware or VirtualBox (VirtualBox is better)

## install minikube
installing minikube is a breeze, first make sure you have some virtual machine technology installed and kubectl, then head over to [minikube start](https://minikube.sigs.k8s.io/docs/start/) and install the correct executable for your OS

(you can now follow minikube tutorial for how to start)
after installing run 
```sh
> minikube start
```

minikube should automaticly create your VM, at first it will take some time, after that you can check your VM status and _kubectl_ config by executing
```sh
> minikube status
minikube status 
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

### check your kubectl
from the output above we can see that `kubeconfig: Configured`, but to make sure things are working run
```bash
> kubectl version
```

if you have incompatible version of _kubectl_ installed with your server, _minikube_ got you, (refer: [minikube start](https://minikube.sigs.k8s.io/docs/start/#what-youll-need) look at step 3)
minikube installs a compatible version of kubectl for you to use
```bash
> minikube kubectl version

# create alias for easy execution

> alias kubectl="minikube kubectl"
```
