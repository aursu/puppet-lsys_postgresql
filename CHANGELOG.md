# Changelog

All notable changes to this project will be documented in this file.

## Release 0.47.0

**Features**

* Added implicit support for Debian and more (with fallback to default version
  defined in `postgresql::globals`)
* Default version for upstream package is 16

**Bugfixes**

**Known Issues**

## Release 0.48.1

**Features**

**Bugfixes**

* CentOS 7: upstream package is 15

**Known Issues**

## Release 0.49.0

**Features**

* Added `libzstd` dependency for CentOS 7

**Bugfixes**

**Known Issues**

## Release 0.50.0

**Features**

* Updated PostgreSQL versions to the latest releases for different OSes
* Updated Puppet modules in fixtures

**Bugfixes**

* Set `service_provider` to `systemd`

**Known Issues**

## Release 0.50.1

**Features**

**Bugfixes**

* Updated GPG keys for RHEL 7

**Known Issues**

## Release 0.50.2

**Features**

**Bugfixes**

* Updated PostgreSQL versions to the latest releases for different OSes

**Known Issues**

## Release 0.50.5

**Features**

**Bugfixes**

* Updated PostgreSQL version to 16.4 for CentOS and Rocky Linux
* Updated PostgreSQL version to 15.8 for CentOS 7

**Known Issues**

## Release 0.52.2

**Features**

* Added new type `Lsys_postgresql::PGListen` for managing PostgreSQL event listening.
* Added containment of the `postgresql::server` class within `lsys_postgresql` to ensure all dependencies are correctly applied.

**Bugfixes**

* Updated PostgreSQL version to 16.6 for Ubuntu
* Pass to `postgresql::server` only string as `listen_addresses`

**Known Issues**

* No known issues in this release.

## Release 0.53.0

**Features**

**Bugfixes**

* Updated PostgreSQL version for CentOS, Rocky and Rocky Linux

**Known Issues**