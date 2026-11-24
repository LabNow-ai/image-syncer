# image-syncer

> **Fork notice:** This project is a fork of [AliyunContainerService/image-syncer](https://github.com/AliyunContainerService/image-syncer), maintained with LabNow-specific fixes and repository organization. Original project and contributions are credited below.

![workflow build](https://github.com/LabNow-ai/image-syncer/actions/workflows/ci.yml/badge.svg)
[![Version](https://img.shields.io/github/v/release/LabNow-ai/image-syncer)](https://github.com/LabNow-ai/image-syncer/releases)
[![Github All Releases](https://img.shields.io/github/downloads/LabNow-ai/image-syncer/total.svg)](https://api.github.com/repos/LabNow-ai/image-syncer/releases)
[![License](https://img.shields.io/github/license/LabNow-ai/image-syncer)](https://www.apache.org/licenses/LICENSE-2.0.html)

`image-syncer` is a docker registry tools. With `image-syncer` you can synchronize docker images from some source registries to target registries, which include most popular public docker registry services.

English | [简体中文](./doc/README-zh_CN.md)

## Quick Install
```bash
setup_image_syncer() {
     local ARCH=$(uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/') \
  && local VER_SYNCER="$(curl_fsSL "https://api.github.com/repos/LabNow-ai/image-syncer/releases?per_page=50" | grep -Po '(?<="tag_name": ")[^"]+' | head -1 | grep -Po '\d[.\d]+')" \
  && local URL_SYNCER="https://github.com/LabNow-ai/image-syncer/releases/download/v${VER_SYNCER}/image-syncer-v${VER_SYNCER}-linux-${ARCH}.tar.gz" \
  && echo "Downloading image-syncer from: ${URL_SYNCER}" \
  && curl -fsSL -o /tmp/image_syncer.tgz "${URL_SYNCER}" \
  && mkdir -pv /tmp/image_syncer && tar -zxvf /tmp/image_syncer.tgz -C /tmp/image_syncer \
  && sudo chmod +x /tmp/image_syncer/image-syncer \
  && sudo mv /tmp/image_syncer/image-syncer /usr/bin/ \
  && rm -rf /tmp/image_syncer* ;
  type image-syncer && echo "@ image-syncer installed to: $(which image-syncer)" || return 1 ;
}
setup_image_syncer
```

## Features

- Support for many-to-many registry synchronization
- Supports docker registry services based on Docker Registry V2 (e.g., Alibaba Cloud Container Registry Service, Docker Hub, Quay.io, Harbor, etc.)
- Network & Memory Only, doesn't rely on any large disk storage, fast synchronization
- Incremental Synchronization, ignore unchanged images automatically
- BloB-Level Concurrent Synchronization, adjustable goroutine numbers
- Automatic Retries of Failed Sync Tasks, to resolve the network problems (rate limit, etc.) while synchronizing
- Doesn't rely on Docker daemon or other programs

## Usage

### GitHub Action

You can use [image-sync-action](https://github.com/marketplace/actions/image-sync-action) to try image-syncer online without paying for any machine resources.

### Install image-syncer

You can download the latest binary release [here](https://github.com/LabNow-ai/image-syncer/releases)

### Compile Manually

```bash
git clone https://github.com/LabNow-ai/image-syncer.git
cd image-syncer

# This will create a binary file named image-syncer in the repository root
make -C src
```

### Example

```bash
# Get usage information
./image-syncer -h

./image-syncer --proc=6 --auth=./auth.json --images=./images.json --retries=3
```

### Configure Files

Image-syncer supports `--auth` and `--images` flag for passing authentication file and image sync configuration file, both of which supports YAML and JSON format. Seperate authentication information is more flexible to reuse it in different sync missions.

> The older version (< v1.2.0) of configuration file is still supported via `--config` flag.

#### Authentication file

Authentication file holds all the authentication information for each registry. For each registry (or namespace), there is a object which contains username and password. For each images sync rule in image sync configuration file, image-syncer will try to find a match in all the authentication information and use the best(longest) fit one. Access will be anonymous if no authentication information is found.

You can find the example in [auth.yaml](examples/auth.yaml) and [auth.json](examples/auth.json), here we use [auth.yaml](examples/auth.yaml) for explaination:

```yaml
quay.io: # This "registry" or "registry/namespace" string should be the same as registry or registry/namespace used below in image sync rules. And if an url match multiple objects, the "registry/namespace" string will actually be used.
  username: xxx
  password: xxxxxxxxx
  insecure: true # Optional, "insecure" field needs to be true if this registry is a http service, default value is false.
registry.cn-beijing.aliyuncs.com:
  username: xxx # Optional, if the value string is a format of "${env}" or "$env", use the "env" environment variables as username.
  password: xxxxxxxxx # Optional, if the value string is a format of "${env}" or "$env", use the "env" environment variables as password.
docker.io:
  username: "${env}"
  password: "$env"
quay.io/coreos:
  username: abc
  password: xxxxxxxxx
  insecure: true
```

#### Image sync configuration file

Image sync configuration file defines all the image sync rules. Each rule is a key/value pair, of which the key refers to "the source images url" and the value refers to "the destination images url". The source/destination images url is mostly the same with the url we use
in `docker pull/push` commands, but still something different in the "tags and digest" part:

1. Neither of the source images url and the destination images url should be empty.
2. If the source images url contains no tags or digest, all the tags of source repository will be synced.
3. The source images url can have more than one tags, which should be seperated by comma, only the specified tags will be synced.
4. The source images url can have at most one digest, and the destination images url should only have no digest or the same digest at the same time.
5. The "tags" part of source images url can be a regular expression which needs to have an additional prefix and suffix string `/`. All the tags of source repository that matches the regular expression will be synced. Multiple regular expressions is not supported.
6. If the destination images url has no digest or tags, it means the source images will keep the same tags or digest after being synced.
7. The destination images url can have more than one tags, the number of which must be the same with the tags in the source images url, then all the source images' tags will be changed to a new one (correspond from left to right).
8. The "destination images url" can also be an array, each of which follows the rules above.

You can find the example in [images.yaml](examples/images.yaml) and [images.json](examples/images.json), here we use [images.yaml](examples/images.yaml) for explaination:

```yaml
quay.io/coreos/kube-rbac-proxy: quay.io/ruohe/kube-rbac-proxy
quay.io/coreos/kube-rbac-proxy:v1.0: quay.io/ruohe/kube-rbac-proxy
quay.io/coreos/kube-rbac-proxy:v1.0,v2.0: quay.io/ruohe/kube-rbac-proxy
quay.io/coreos/kube-rbac-proxy@sha256:14b267eb38aa85fd12d0e168fffa2d8a6187ac53a14a0212b0d4fce8d729598c: quay.io/ruohe/kube-rbac-proxy
quay.io/coreos/kube-rbac-proxy:v1.1:
  - quay.io/ruohe/kube-rbac-proxy1
  - quay.io/ruohe/kube-rbac-proxy2
quay.io/coreos/kube-rbac-proxy:/a+/: quay.io/ruohe/kube-rbac-proxy
```

### Parameters

```
-h  --help       Usage information

    --config     Set the path of config file, this file need to be created before starting synchronization, default
                 config file is at "current/working/directory/config.json". (This flag can be replaced with flag --auth
                 and --images which for better orgnization.)

    --auth       Set the path of authentication file, this file need to be created before starting synchronization, default
                 config file is at "current/working/directory/auth.json". This flag need to be pair used with --images.

    --images     Set the path of image rules file, this file need to be created before starting synchronization, default
                 config file is at "current/working/directory/images.json". This flag need to be pair used with --auth.

    --log        Set the path of log file, logs will be printed to Stderr by default

    --proc       Number of goroutines, default value is 5

    --retries    Times to retry failed tasks, default value is 2, the retries of failed tasks will start after all the tasks
                 are executed once, this can resolve most occasional network problems during synchronization

    --os         OS list to filter source tags, not works for docker v2 schema1 media, takes no effect if empty

    --arch       Architecture list to filter source tags, takes no effect if empty

    --force      Force update manifest whether the destination manifest exists
```

### FAQs

Frequently asked questions are listed in [FAQ](./doc/FAQ.md)
