---
title: HPC Containers with Singularity
author: Ben Evans
date: December 4, 2018
---

# Outline for Today
- Containers Background
- Docker & Singularity
- Running Singularity
- Development Workflow

# Containers

<section>
# 
### Definitions

- _**Container Image**_: A self-contained file(s) needed to run application(s)

- _**Container**_: A running instance of an image

# 
### Three methods of control

- Process isolation 
    - Linux [Namespaces](https://en.wikipedia.org/wiki/Linux_namespaces) (chrome uses for [sandboxes](https://chromium.googlesource.com/chromium/src/+/HEAD/docs/linux_sandboxing.md))
- Resource Limits 
    - Linux [cgroups](https://en.wikipedia.org/wiki/Cgroups)
- Security
    - When user is trusted: [SELinx](https://en.wikipedia.org/wiki/Security-Enhanced_Linux), [AppArmor](https://en.wikipedia.org/wiki/AppArmor)
    - When user is untrusted: run container as user

# 
| Pro                | Con                               |
|--------------------|-----------------------------------|
| Light-weight       | Linux best supported              |
| Fast start time    | Another layer of abstraction      |
| Batteries included | Additional development complexity |
| Shareable          | Licensed software can be tricky   |
| Reproducible       |                                   |

</section>

# Example

GPU-enabled IPython w/TensorFlow on a GPU node:

```bash
srun --pty -p gpu -c 2 --gres gpu:1 --mem 24G \
  singularity exec --nv \
    docker://tensorflow/tensorflow:latest-gpu ipython
```

# Docker
<section>
![](img/docker_logo.svg)

# 
- Most popular container application
- Publicly [announced](https://www.youtube.com/watch?v=wW9CAH9nSLs) in 2013
- Designed to run services
    - Often used for web apps
- Primary registry hub.docker.com

# 
- Service runs to orchestrate
- Images are composed of separate files: layers
- Designed to be run with elevated privileges

#

![](img/docker_layout.png)

</section>

# Singularity

<section>
![](img/singularity_logo.png)

# 
- Released in 2016, [paper in 2017](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0177459)
- Designed to run compute jobs
- Sylabs re-written, OSS/support model
    - v2.6 and v3 different, not backwards-compatible
- Registries: singularity-hub.org cloud.sylabs.io/library

# 
- No services needed to run
- Images are single files
    - Read-only by default
- Designed to be run as unprivileged user
</section>

# Running Singularity
<section>

#

```bash
singularity run image.simg

singularity exec docker://org/image program --option=value

singularity shell -s /bin/bash library://image
```
# 
**`singularity run`**

- Executes whatever `%runscript` or `ENTRYPOINT` specifies
- Additional arguments are passed to default action

# 
**`singularity exec`**

- First argument after container is run /w its arguments
- Must be on the `PATH` inside the container

# 
**`singularity shell`**

- Run an interactive shell inside the container
- Specify a different one with `-s/--shell`

</section>

# Simplest Case

<section>

My application is available as a container image from somewhere.

# 
- Build\* or copy singularity image locally

```bash
# 2.6
singularity build my_container.simg \
   docker://brevans/my_container:latest
# 3.0
singularity build my_container.sif \
   docker://brevans/my_container:latest
```
\* You can only build containers from docker/shub/library on cluster

# 
Use the image

```bash
singularity run my_container.simg inputfile.txt \
   /gpfs/ysm/project/be59/output_folder

singularity exec my_container.simg python my_script.py
singularity shell -s /bin/bash my_container.simg
```
</section>

# Runtime Config
<section>

#
Docker links take the form of:

```
docker://[registry]/[namespace]/<repo_name>:[repo_tag]
```
<br>

- Registry: default [index.docker.io]
- Namespace: username, org, or the default [library]
- Repo: image name
- Tag: name (e.g. latest) or hash (e.g. @sha256:1234...)

#

You may want to modify the container's environment at runtime

- Set variables inside the container by prefixing them with `SINGULARITYENV_`
- Modifying `PATH`:
    - `SINGULARITYENV_PREPEND_PATH` - prepend
    - `SINGULARITYENV_APPEND_PATH` - append
    - `SINGULARITYENV_PATH` - override

#

- Pulling Docker images can take up many GiB
- You may want to change where these files are cached

```bash
# default is ~/.singularity
export SINGULARITY_CACHEDIR=~/scratch60/.singularity
# or
export SINGULARITY_CACHEDIR=/tmp/${USER}/.singularity
```
# 
- Your image may expect input or output files to be somewhere specific, e.g. `/data`
- You can bind a directory to this path with `-B/--bind`:

```bash
singularity run --bind /path/outside:/path/inside \
   my_container.simg
```

#

- You may need to specify Docker Hub credentials
- Be wary of storing credentials in your shell history

```bash
set +o history
export SINGULARITY_DOCKER_USERNAME=brevans
export SINGULARITY_DOCKER_PASSWORD=password123
set -o history
```

#

- Quick way to determine which files are included in image
```
singularity run/exec/shell --containall ...
```

#

- Bind GPU drivers properly with CUDA runtime installed inside container
```
singularity run/exec/shell --nv ...
```

</section>

# RStudio Example
<section>
I want to run the newest RStudio and tidyverse.

see: [rocker-project.org](https://www.rocker-project.org/)

#
job file:
```bash
#!/bin/bash
#SBATCH -c 4 -t 2-00:00:00
mkdir -p /tmp/${USER}
export SINGULARITYENV_DISABLE_AUTH=true
singularity run -B /tmp/${USER}:/tmp \
   docker://rocker/geospatial:3.5.1
```

#
Reverse `ssh` tunnel:
```bash
ssh -NL 8787:cxxnxx:8787 grace.hpc.yale.edu
```
Then connect to http://localhost:8787

#
- Not the best...
- [According to docs](https://support.rstudio.com/hc/en-us/articles/200552316-Configuring-the-Server), we have to rebuild the container
- Change `/etc/rstudio/rserver.conf`

</section>

# Dev Workflow
<section>

When you have to configure your own

#

![](img/workflow_diagram.svg)

# 
### Reasoning

- Docker/Docker Hub ecosystem large, stable
- Docker re-builds can be faster
- Docker Hub can auto-build github repos
- More easily use docker on other platforms

#
### Best Practices

- Don’t install anything to root’s home, `/root`
- Don’t put container valuables in `$TMP` or `$HOME`
- Use `ENTRYPOINT` to specify default runtime behavior
- Update shared library cache by calling `ldconfig` at the end of your `Dockerfile`

</section>

# [Dockerfiles](https://docs.docker.com/engine/reference/builder)
<section>

A half-fix for my RStudio issue

```dockerfile
FROM rocker/geospatial:3.5.1
LABEL maintainer="b.evans@yale.edu" version=0.01

ENV RSTUDIO_PORT=30301
RUN echo "www-port=${RSTUDIO_PORT}" >> /etc/rstudio/rserver.conf
```
#

- Recipes for container images
- File always named `Dockerfile`
- 

#

## [FROM](https://docs.docker.com/engine/reference/builder/#from)
Sets base image

```dockerfile
FROM ubuntu:bionic
FROM ubuntu@sha256:6d0e0c26489e33f5a6f0020edface2727db9489744ecc9b4f50c7fa671f23c49
```
- Required, usually first
- Hashes are more reproducible.

# 
## [LABEL](https://docs.docker.com/engine/reference/builder/#label)
Annotate your container image with metadata.
```dockerfile
LABEL maintainer="ben evans <b.evans@yale.edu>"
LABEL help="help message"
```
- Good to at least specify a maintainer email.

# 
## [ENV](https://docs.docker.com/engine/reference/builder/#env)
Set environment variables. 
```dockerfile
ENV PATH=/opt/my_app/bin:$PATH MY_DB=/opt/my_app/db ...
```

- Available for subsequent layers, and at runtime.

# 
## [RUN](https://docs.docker.com/engine/reference/builder/#run)
Run commands to build your image.
```dockerfile
RUN apt-get update && \
    apt-get install openmpi-bin \
                    openmpi-common \
                    wget \
                    vim 
```

- Each `RUN` instruction is a separate layer.
- Suggested style: one package per line, alphabetical

# 
## [COPY](https://docs.docker.com/engine/reference/builder/#copy)
Copy files from your computer to the image.
```dockerfile
COPY <host_src>... <container_dest>
```

- I usually try to download them instead

# 
## [ENTRYPOINT](https://docs.docker.com/engine/reference/builder/#entrypoint)
Specify a default action.
```dockerfile
ENTRYPOINT ["/opt/conda/bin/ipython", "notebook"]
```

- Used for docker run and singularity run.

</section>

# Docker Dev
<section>

# 
### Tips
- Put most troublesome RUNs at the end
- Use git to version your Dockerfile
- **Only** use ENTRYPOINT (not CMD) if you plan to use Singularity
- Use [docker inspect](https://docs.docker.com/engine/reference/commandline/inspect/) to get container image info
```
docker inspect ubuntu:bionic
docker inspect --format='{{index .RepoDigests 0}}' ubuntu:bionic
```

# 
### Build
How to [build](https://docs.docker.com/engine/reference/commandline/build/) locally
```bash
cd /path/to/Dockerfile_dir/
docker build -t custom_ubuntu:testing .
```

#
### Run
How to [run](https://docs.docker.com/engine/reference/run/) Docker locally

```bash
# default
docker run --rm /bin/bash custom_ubuntu:testing
# interactive
docker run --rm -ti --entrypoint /bin/bash custom_ubuntu:testing 
```

- use `--rm` to clean up container after it exits

#
### Push
[Send your container](https://docs.docker.com/docker-cloud/builds/push-images/) to Docker Hub for use elsewhere
```
export DOCKER_ID_USER="username"
docker login
docker tag custom_ubuntu:testing $DOCKER_ID_USER/my_image:v0.1
docker push $DOCKER_ID_USER/my_image
```

# 
### Clean

Clean up using Docker prune every now and again.
```bash
docker system prune
WARNING! This will remove:
        - all stopped containers
        - all networks not used by at least one container
        - all dangling images
        - all dangling build cache
Are you sure you want to continue? [y/N]
```

</section>

# Links
<section>
[Docker Documentation](https://docs.docker.com/)

Install Docker on [MacOS](https://docs.docker.com/docker-for-mac/), [Windows](https://docs.docker.com/docker-for-windows/), and [Linux](https://docs.docker.com/install/linux/ubuntu/)

[Ubuntu](https://hub.docker.com/_/ubuntu/) and [CentOS](https://hub.docker.com/_/centos/) [Docker Hub](https://hub.docker.com/) pages

[`Dockerfile` reference](https://docs.docker.com/engine/reference/builder)

[`docker` CLI reference](https://docs.docker.com/engine/reference/commandline/docker/)

#
[Singularity Documentation](https://www.sylabs.io/docs/)

Install Singularity [v3](https://www.sylabs.io/guides/3.0/user-guide/quick_start.html#quick-installation-steps) and [v2](https://www.sylabs.io/guides/2.6/user-guide/installation.html)

Container [recipe reference](https://www.sylabs.io/guides/2.6/user-guide/container_recipes.html#container-recipes)

YCRC [abridged Singularity docs](https://research.computing.yale.edu/support/hpc/user-guide/singularity-yale)
</section>