# OpenGrok docker

[TOC]

## Features

- 

## Usage

### To Start

```sh
$ docker run --rm -d --name=grok -v /src:/grok/src -p 8080:8080 shunlir/opengrok
```

By default, the index will be rebuild dynamically upon updating through `inotifywait` on the source folder, or every 120 minutes at most. 

You can use `-e REINDEX=0` to disable auto indexing:

```sh
$ docker run --rm -d -e REINDEX=0 --name=grok -v /src:/grok/src -p 8080:8080 shunlir/opengrok
```

then you can use docker exec to trigger re-index at your own:

```sh
$ docker exec grok grok_index
```

Note:  if you have more than 8192 files to watch, you will need to increase the amount of inotify watches allowed per user (`/proc/sys/fs/inotify/max_user_watches`) on your host system.

### The Web interface

The web interface is available at `http://localhost:8080/source`, `/` will redirect to `/source`

## Advance Usage

- You can disable `inotify` using `INOTIFY=0` environment:

```sh
$ docker run --rm -d -e INOTIFY=0 --name=grok -v /src:/grok/src -p 8080:8080 shunlir/opengrok
```

Note: auto-indexing will be done every 120 minutes.

- You can adjust this time (in Minutes) by passing the `REINDEX `environment variable:

```sh
$ docker run --rm -d -e REINDEX=30 --name=grok -v /src:/grok/src -p 8080:8080 shunlir/opengrok
```

- Run container with volume for `/grok/etc`

```sh
$ docker volume create grok_etc
$ docker run --rm -d --name=grok -v /src:/grok/src -v grok_etc:/grok/etc -p 8080:8080 shunlir/opengrok
$ docker volume inspect grok_etc # find the Mountpoint
```

- To run a full index after projects added/removed in the source folder

```sh
$ docker exec grok grok_index # rebuild index of all projects one by one
```

Or use the following combination:

```sh
$ docker exec grok grok_index --noIndex # generate bare configuration for web interface
$ docker exec grok grok_reindex # rebuild index of all projects in parallel
```

Note: `grok_reindex` doesn't scan `/src` to find added/removed projects/repositories, that's why `grok_index --noIndex` is invoked first.

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



