---
title: HPC Containers with Singularity
author: Ben Evans
date: December 4, 2018
---

# Outline for Today
* Anatomy of a container
* Why containers?
* Current Workflow Suggestions
* Docker & Singularity
* Examples
    * Dockerfiles
    * Singularity recipes

# What is a Container?
* Process isolation 
    * Linux Namespaces
* Resource Limits
    * Linux [cgroups](https://en.wikipedia.org/wiki/Cgroups)
* Security (?)
    * [SELinx](https://en.wikipedia.org/wiki/Security-Enhanced_Linux), [AppArmor](https://en.wikipedia.org/wiki/AppArmor)

# Advantages
* Light-weight
* "Batteries included"
* Shareable
* Reproducible*
<br><br>
\* probably

# Table


|   | Docker | Singularity |
|---|--------|-------------|
|   |     item   |             |
|   |        |   another item          |
|   |    56    |      `code` and stuff       |

# dockerfile

```dockerfile
RUN echo "this is a dockerfile" && \
    cd /home/root
```
