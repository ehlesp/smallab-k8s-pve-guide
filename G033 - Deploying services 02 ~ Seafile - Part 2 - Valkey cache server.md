# G033 - Deploying services 02 ~ Seafile - Part 2 - Valkey cache server


## Use Valkey as an alternative for Redis with Seafile

This second part of the Seafile deployment procedure is where you begin working with the Kustomize project for the whole Seafile platform's setup. In particular, you will prepare the Kustomize subproject for a [Valkey](https://valkey.io/) server that will act as the caching component of your Seafile platform.

Valkey started as a fork of Redis but nowadays they are considered different and independent from each other. Still, you can deploy Valkey with Nextcloud and use it exactly like a Redis caching server.