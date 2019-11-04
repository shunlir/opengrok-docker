# OpenGrok docker

[TOC]

## Features

- auto-indexing (inotify-based and scheduled).
- index multiple projects in parallel.
- show information in opengrok web interface while building index.
- project group wrapper.

## Usage

### To Start

```sh
$ docker run --rm -d \
    --name=grok \
    -v /grok/src:/grok/src \
    -v /grok/data:/grok/data \
    -v /grok/log:/grok/log \
    -p 8080:8080 \
    shunlir/opengrok
```

> By default, the index will be rebuild automatucally 1) changes detected through `inotifywait` in the source folder, or 2) every 120 minutes.  

> Note:  if you have more than 8192 files to watch, you will need to increase the amount of inotify watches allowed per user (`/proc/sys/fs/inotify/max_user_watches`) on your host system.

- You can use `-e REINDEX=0` to disable auto indexing.
- You can use `-e INOTIFY=0` to disable source folder change monitoring.
- You can use `grok_index` to do increamental index maunally at any time: `$ docker exec grok grok_index`

### The Web interface

The web interface is available at `http://localhost:8080/source`, `/` will redirect to `/source`

## Advance Usage

- You can adjust auto reindex time interval (in Minutes) by passing the `REINDEX `environment variable:

```sh
$ docker run --rm -d \
    --name=grok \
    -e REINDEX=30 \
    -v /grok/src:/grok/src \
    -p 8080:8080 \
    shunlir/opengrok
```

- Run container with volume for `/grok/etc`

```sh
$ docker run --rm -d \
             --name=grok \
             -v /src:/grok/src \
             -v grok_etc:/grok/etc \
             -p 8080:8080 \
             shunlir/opengrok
$ docker volume inspect grok_etc # find the Mountpoint
```

- To run a full index after projects added/removed in the source folder

```sh
$ docker exec grok grok_index # rebuild index of all projects one by one
```

Or use the following combination:

```sh
$ docker exec grok grok_index --noIndex # generate bare configuration for web interface, project list will be empty in web interface, issue?
$ docker exec grok grok_reindex         # rebuild index of all projects in parallel
```

> Note: `grok_reindex` doesn't scan `/src` to find added/removed projects/repositories in the fly, that's why `grok_index --noIndex` is invoked first.

- To trigger re-indexing after contents of projects in`/src` are changed:

```sh
$ docker exec grok grok_reindex
```

- To re-index a single project:

```sh
$ docker exec grok grok_reindex <proj1> [proj2 ...]
```

- grok_groups:

```sh
$ grok_groups -h
usage: grok_groups -l | {[-p parent_group] -n new_group -r "pattern1|pattern2|..."}
```



