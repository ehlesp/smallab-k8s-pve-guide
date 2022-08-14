# Small homelab K8s cluster on Proxmox VE

Would you like to practice with K8s/Kubernetes? Do you happen to have one spare computer at hand? Then this guide series may be right for you! In it I explain how to configure a server able to run a small Kubernetes cluster, set up with just a few virtual machines.

The title says "small homelab", meaning that I've written the guides having in mind the sole low-end consumer computer I had (and still have) available for it. Don't get me wrong, by the way. The hardware contemplated is limited but capable for the proposed task. You'll see what I mean in the very first [**G001** guide](G001%20-%20Hardware%20setup.md), in which I explain my hardware setup in detail.

You might be wondering, aren't already out there guides explaining how to build such a server? Well, not exactly. Most of the guides I've seen expect you to have a number of computers (Raspberry PIs usually) available to use as nodes of your K3s-based Kubernetes cluster. What I had was one basic computer, nothing more, but I could surmount my lack of extra computers with virtual machines.

On the other hand, most of those guides you'll find on internet use alternative tools (**k3sup** and **helm** come to mind) to handle the installation and configuration of those nodes. I wanted to go down the hard path first, building a Kubernetes cluster from scratch as close to the standard `kubectl` way as possible, so using those tools was out of the question. Still, some of those guides served me as reference in some cases, and you'll find some of them linked as references at the bottom of some of my guides.

Beyond those two previous considerations, there's also the fact that the information of the things I wanted, or needed, to do in my homelab is quite scattered on the internet. I knew that it would be very convenient for me to put in one place all the things I've done and the references I've followed. I also realized that, since my build is rather generic, I could go the extra mile and format the guides so they could be useful for anyone with a spare computer like mine (or a better one even).

So, in this guide series I offer you, **in one place**, a collection of procedures to run a small Kubernetes cluster with virtual machines in a single computer.

## Description of contents

The procedures explained in this guide series deal mainly with three concepts:

- How to install and configure a virtualization platform.
- How to setup a small Kubernetes cluster with VMs.
- How to deploy applications on the Kubernetes cluster.

Within those main concepts, I've also covered (up to a point) things like hardening, firewalling, optimizations, backups and a few other things that came up while I was working on my server's setup.

Each guide in the series is detailed and explanatory, only omitting things when they've been done in a previous step or guide, or is understood that the reader should know about them already.

Also, since the whole series is about building a concrete setup, the guides are related to each other, so they're more like chapters than independent guides. Still, each guide is usually about one main concept or procedure, and the setup serves as an example of how to implement it.

## Intended audience

In general, anyone with some background in Linux and virtual machines that also has an interest in Kubernetes. And, more broadly, anyone with the need or the curiosity to run Kubernetes on a single capable-enough consumer-grade computer.

## Goals

The main goal, for the build explained in this guide series, is to turn a rather low-end consumer computer into a small Kubernetes homelab.

The core platforms I use in this guide series to build the homelab are:

- Virtualization platform: [Proxmox Virtual Environment](https://www.proxmox.com/en/) in a standalone node.
- [Rancher K3s](https://k3s.io/) [Kubernetes](https://kubernetes.io/) distribution for building the small Kubernetes cluster with KVM virtual machines run by the Proxmox VE standalone node.

After setting up the Kubernetes cluster, the idea is to deploy in it the following.

- File cloud: [Nextcloud](https://nextcloud.com/).
- Lightweight git server: [Gitea](https://gitea.io/).
- Kubernetes cluster monitoring stack: set of monitoring modules including [Prometheus](https://prometheus.io/), [Grafana](https://grafana.com/grafana/) and a couple of other related services.

Also, the whole system will have some backup procedures applied to it.

## Table of contents

All the guides and their main sections are easily accessible through the [Table Of Contents](G000%20-%20Table%20Of%20Contents.md) of this guide series.

## Navigation

[+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G001. Hardware setup**) >>](G001%20-%20Hardware%20setup.md)
