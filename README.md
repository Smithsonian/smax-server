![Test installer](https://github.com/Smithsonian/smax-server/actions/workflows/test.yml/badge.svg)

<picture>
  <source srcset="resources/CfA-logo-dark.png" alt="CfA logo" media="(prefers-color-scheme: dark)"/>
  <source srcset="resources/CfA-logo.png" alt="CfA logo" media="(prefers-color-scheme: light)"/>
  <img src="resources/CfA-logo.png" alt="CfA logo" width="400" height="67" align="right"/>
</picture>
<br clear="all">

# SMA-X server setup

The SMA information eXchange (SMA-X) is a high performance and versatile data sharing platform for distributed 
software systems. It is built around a central Redis database, and provides atomic access to structured data, 
including specific branches and/or leaf nodes, with associated metadadata. SMA-X was developed at the Submillimeter
Array (SMA) observatory, where we use it to share real-time data among hundreds of computers and nearly a thousand
individual programs.

SMA-X consists of a set of server-side [LUA](https://lua.org/) scripts that run on [Redis](https://redis.io) (or one 
of its forks / clones such as [Valkey](https://valkey.io) or [Dragonfly](https://dragonfly.io)); a set of libraries to 
interface client applications; and a set of command-line tools build with them. Currently we provide client libraries 
for C/C++ and Python 3. We may provide Java and/or Rust client libraries too in the future.

This repository is for the SMA-X server configuration specifically. It contains a LUA scripts, a script to load them into
a database and a `systemd` unit file that allows to load the SMA-X scripts automatically whenever Redis is started.


## Prerequisites

Before you install the SMA-X server configuration, you will need to install [Redis](https://redis.io) (or one 
of its forks / clones such as [Valkey](https://valkey.io) or [Dragonfly](https://dragonfly.io)). On Linux you may simply 
use your package manager such as `dnf` (RPM-based distros) or `apt` (Debian-based distros).

After installing Redis (or equivalent), edit `/etc/redis.conf` (or equivalent) to customize for your system. We provide
a sample configuration file for local connections (from 127.0.0.1 only) and with logging enabled (see `redis.conf` in 
this repo). You may want to edit the `bind` setting to allow connections to your Redis server from your local network.

## Installing

After you have installed and configured Redis (or equivalent), you can configure the Redis server for SMA-X. Simply run

```bash
  sudo ./install.sh
```

It will ask you some questions on how exactly you want SMA-X to be installed and deployed.

After a successful installation you may use `systemctl` to manage `redis` and the `smax-scripts` services.


## Related GitHub repos

For a C/C++ client library for SMA-X see [Smithsonian/smax-clib](https://github.com/Smithsonian/smax-clib), or for a 
Python library use [Smithsonian/smax-python](https://github.com/Smithsonian/smax-python). To archive SMA-X data 
sampled at regular intervals into a Postgres database, see 
[Smithsonian/smax-postgres](https://github.com/Smithsonian/smax-postgres)
