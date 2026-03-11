# Small homelab K8s cluster on Proxmox VE

- [A complete guide for building a virtualized Kubernetes homelab](#a-complete-guide-for-building-a-virtualized-kubernetes-homelab)
- [Main concepts](#main-concepts)
- [Intended audience](#intended-audience)
- [Goal of this guide](#goal-of-this-guide)
- [Software used](#software-used)
- [Table of contents](#table-of-contents)
- [References](#references)
  - [Software](#software)
  - [GitHub Docs](#github-docs)
- [Navigation](#navigation)

## A complete guide for building a virtualized Kubernetes homelab

Welcome to the revised version of this guide for building your own small Kubernetes homelab with a low-end consumer-grade computer. Its chapters offer procedures to setup a virtualization platform where to run a compact Kubernetes cluster using virtual machines as nodes. Not only that, here you can find concrete examples of app deployments showing how to make real use of your Kubernetes cluster. Furthermore, this guide also contains instructions covering other details such as hardening, backups, or updates planning.

This guide avoids using tools such as K3sup, Terraform or Helm to handle Kubernetes-related tasks. For the most part, it only uses the official `kubectl` command and Kustomize-based declarations. On the hardware side, the real computer this guide is based on might surprise you with its somewhat limited specifications. The first [chapter **G001**](G001%20-%20Hardware%20setup.md) explains its specifications in detail, and may help you budget your own homelab setup better.

On the other hand, although this guide explains a lot of the stuff done in it, it is not designed to teach about Linux, virtualization, or Kubernetes. It only explains stuff to make clear why certain technical decisions were made on each of its chapters, or to warn about particular issues that can happen in the setup. It is better to think about this guide as a cookbook where each chapter is a recipe to solve a specific concern from the same scenario.

It is also important to highlight that this guide is complete. Its core goal is fully covered by its main chapters, and even provides some extra information in the form of appendixes. In other words, this guide offers you, in one place, a complete set of instructions to build and run a small Kubernetes cluster with virtual machines on a single consumer-grade computer.

## Main concepts

The procedures explained in this guide deal mainly with three concerns:

- How to install and configure the Proxmox VE virtualization platform.
- How to setup a small Kubernetes cluster with VMs.
- How to deploy applications on the Kubernetes cluster.

Within those main concepts, this guide also covers (up to a point) details like hardening, firewalling, optimizations, backups and a few other things that came up while working in the  homelab set up by this guide.

Each chapter in the guide is detailed and explanatory, only omitting things when they have been already done in a previous step or chapter, or is understood that the reader should know about them already. Also, each chapter is usually about one main concern or procedure, and the guide's setup serves as the example scenario illustrating how to implement it.

> [!NOTE]
> **This guide has been written in GitHub Flavored Markdown format**\
> All the chapters of this guide are [GitHub Flavored Markdown](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/about-writing-and-formatting-on-github) documents you can visualize rendered as HTMLs either in GitHub directly or in compatible Markdown viewers or editors.

## Intended audience

Anyone with some background in Linux and virtual machines having an interest in Kubernetes. Also, those with the need or the curiosity to run Kubernetes on a single capable-enough consumer-grade computer.

## Goal of this guide

The main goal, for the build explained in this guide, is to turn a rather low-end consumer-grade computer into a small Kubernetes homelab able to run some practical workloads.

## Software used

The core software used in this guide to build the homelab is:

- [Proxmox Virtual Environment](https://www.proxmox.com/en/) in a standalone node as the virtualization platform of choice.

- [Rancher K3s](https://k3s.io/) [Kubernetes](https://kubernetes.io/) distribution for building the small Kubernetes cluster with KVM virtual machines run by the Proxmox VE standalone node.

After setting up the Kubernetes cluster, the idea is to deploy in it the following software:

- Publishing platform: [Ghost](https://ghost.org/).
- Lightweight git server: [Forgejo](https://forgejo.org/).
- Monitoring stack: set of monitoring modules including [Prometheus](https://prometheus.io/), [Grafana](https://grafana.com/grafana/) and a couple of other related services.

Also, the resulting homelab has some backup features enabled in it.

## Table of contents

All the chapters and their main sections are directly accessible through this guide's [Table Of Contents](G000%20-%20Table%20Of%20Contents.md).

## References

### Software

- [Proxmox Virtual Environment](https://www.proxmox.com/en/)
- [Rancher K3s](https://k3s.io/)
- [Kubernetes](https://kubernetes.io/)
- [Forgejo](https://forgejo.org/)
- [Ghost](https://ghost.org/)
- [Prometheus](https://prometheus.io/)
- [Grafana](https://grafana.com/grafana/)

### [GitHub Docs](https://docs.github.com/en)

- [Get started. Writing on GitHub](https://docs.github.com/en/get-started/writing-on-github)
  - [Getting started with writing and formatting on GitHub](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/)
    - [About writing and formatting on GitHub](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/about-writing-and-formatting-on-github)

## Navigation

[<< Previous (**G910. Appendix 10**)](G910%20-%20Appendix%2010%20~%20Updating%20PostgreSQL%20to%20a%20newer%20major%20version.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G001. Hardware setup**) >>](G001%20-%20Hardware%20setup.md)
