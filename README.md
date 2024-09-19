![Installer status](https://github.com/Smithsonian/smax-server/actions/workflows/test.yml/badge.svg)

<picture>
  <source srcset="resources/CfA-logo-dark.png" alt="CfA logo" media="(prefers-color-scheme: dark)"/>
  <source srcset="resources/CfA-logo.png" alt="CfA logo" media="(prefers-color-scheme: light)"/>
  <img src="resources/CfA-logo.png" alt="CfA logo" width="400" height="67" align="right"/>
</picture>
<br clear="all">

# smax-server

[SMA Exchange (SMA-X)](https://docs.google.com/document/d/1eYbWDClKkV7JnJxv4MxuNBNV47dFXuUWu7C4Ve_YTf0/edit?usp=sharing)
structured real-time database server configuration kit.

Last updated: 19 September 2024


## Table of contents

 - [Introduction](#introduction)
 - [Prerequisites](#prerequisites)
 - [Installation](#installing)

------------------------------------------------------------------------------

<a name="introduction"></a>
## Introduction

The [SMA Exchange (SMA-X)](https://docs.google.com/document/d/1eYbWDClKkV7JnJxv4MxuNBNV47dFXuUWu7C4Ve_YTf0/edit?usp=sharing) 
is a high performance and versatile real-time data sharing platform for distributed software systems. It is built 
around a central Redis database, and provides atomic access to structured data, including specific branches and/or 
leaf nodes, with associated metadadata. SMA-X was developed at the Submillimeter Array (SMA) observatory, where we use 
it to share real-time data among hundreds of computers and nearly a thousand individual programs.

SMA-X consists of a set of server-side [LUA](https://lua.org/) scripts that run on [Redis](https://redis.io) (or one 
of its forks / clones such as [Valkey](https://valkey.io) or [Dragonfly](https://dragonfly.io)); a set of libraries to 
interface client applications; and a set of command-line tools built with them. Currently we provide client libraries 
for C/C++ and Python 3. We may provide Java and/or Rust client libraries too in the future.

This repository is for the SMA-X server configuration specifically. It contains a LUA scripts, a shell script to load 
them into a database, and a `systemd` unit file that allows to load the SMA-X scripts automatically whenever Redis is 
started.


 <a name="related-links"></a>
### Related links

 - [SMA-X specification](https://docs.google.com/document/d/1eYbWDClKkV7JnJxv4MxuNBNV47dFXuUWu7C4Ve_YTf0/edit?usp=sharing) 
   document
 - [Smithsonian/smax-clib](https://github.com/Smithsonian/smax-clib) -- a C/C++ client library for SMA-X
 - [Smithsonian/smax-python](https://github.com/Smithsonian/smax-python) -- a Python 3 client library for SMA-X
 - [Smithsonian/smax-postgres](https://github.com/Smithsonian/smax-postgres) -- to create a historical records of SMA-X data in a PostgreSQL time series database.

<a name="prerequisites"></a>
## Prerequisites

Before you install the SMA-X server configuration, you will need to install [Redis](https://redis.io) (or one 
of its forks / clones such as [Valkey](https://valkey.io) or [Dragonfly](https://dragonfly.io)). On Linux you may simply 
use your package manager such as `dnf` (RPM-based distros) or `apt` (Debian-based distros).

After installing Redis (or equivalent), edit `/etc/redis.conf` (or equivalent) to customize for your system. We provide
a sample configuration file for local connections (from 127.0.0.1 only) and with logging enabled (see `redis.conf` in 
this repo). You may want to edit the `bind` setting to allow connections to your Redis server from your local network.

<a name="installing"></a>
## Installation

 - [Linux install with systemd](#linux-install)
 - [Manual installation](#manual-install)

<a name="linux-install"></a>
### Linux install with systemd

These instructions are for Linux systems (RPM or Debian based) using `systemd`. 

After you have installed and configured Redis (or equivalent), you can configure the Redis server for SMA-X. Simply run

```bash
  sudo ./install.sh
```

It will ask you some questions on how exactly you want SMA-X to be installed and deployed. Optionally, you may define
an alternative installation mode as an argument to `install.sh`. The following modes are supported:

 - `auto`: Automatic installation and startup
 - `sma` : Automatic installation and startup at the Submillimeter Array (SMA)
 - `help`: Provides a simple help screen only.
 
Additionally, you may define a couple of shell variables prior to invoking `install.sh` to guide its behavior:

 - `DESTDIR` : Set the deployment root directory (default is `/usr`)
 - `PREFIX`  : Set a staging prefix. If `PREFIX` is defined and not empty, `install.sh` will stage only, without
   starting up services (which are not yet in their final location).

After a successful installation you may use `systemctl` to manage `redis` and the `smax-scripts` services.


<a name="manual-install"></a>
### Manual installation

You can also install and configure SMA-X manually, for non-systemd and/or non-Linux systems (e.g. MacOS X, BSD,
Linux SysV, Windows), following the steps below:

1. Configure your Redis server, for your network and other preferences.

2. Copy the LUA scripts from the `lua/` folder to an appropriate location for your boot service manager (e.g. 
   `/usr/share/smax/lua` or equivalent). Optionally, edit the LUA scripts to remove any SMA-specific content, which 
   is clearly marked.
   
3. If your system has bash, copy `smax-init.sh` to an appropriate location (e.g. `/usr/bin` or equivalent) from where 
   your service manager may run it. Edit the script to reflect the location where you installed the LUA scripts. 
   Alternatively, you may create a similar initializer for your system using the script language of your choice. 
   (`smax-init.sh` simply uses a set of `redis-cli` commands to initialize a Redis database for SMA-X.)

4. To start SMA-X on boot, first make sure that the Redis server is started on boot. Conditional on Redis being 
   available, you should then configure your system to run the loader script (`smax-init.sh` or equivalent) also on 
   boot, after Redis.
   
5. Reboot or else start Redis and run the LUA script loader manually.



