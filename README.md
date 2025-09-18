# lsys_postgresql

A Puppet module for installing and configuring PostgreSQL server with intelligent OS-specific defaults and repository management.

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with lsys_postgresql](#setup)
    * [What lsys_postgresql affects](#what-lsys_postgresql-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with lsys_postgresql](#beginning-with-lsys_postgresql)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference](#reference)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

This module provides a streamlined way to install and configure PostgreSQL server across different Linux distributions. It wraps the `puppetlabs/postgresql` module with intelligent defaults and handles OS-specific repository management, version selection, and configuration.

**Key Features:**
- **OS-aware version management**: Automatically selects appropriate PostgreSQL versions for different operating systems
- **Repository management**: Handles PostgreSQL official repositories with proper GPG keys and SSL verification
- **DNF module support**: Manages DNF module streams on RHEL/CentOS 8+ systems
- **Network configuration**: Simplifies PostgreSQL network access configuration
- **Contrib packages**: Automatically installs PostgreSQL contrib extensions

## Setup

### What lsys_postgresql affects

This module manages:

* **Packages**: PostgreSQL server, client, and contrib packages
* **Services**: PostgreSQL service (postgresql/postgresql-X)  
* **Configuration files**: 
  - `/var/lib/pgsql/X/data/postgresql.conf`
  - `/var/lib/pgsql/X/data/pg_hba.conf`
* **Repositories**: 
  - PostgreSQL official APT/YUM repositories
  - EPEL repository (on RHEL/CentOS systems)
  - DNF module streams (on RHEL/CentOS 8+)
* **Repository files**:
  - `/etc/yum.repos.d/yum.postgresql.org.repo`
  - `/etc/yum.repos.d/pgdg-common.repo`
* **GPG keys**: PostgreSQL repository signing keys

### Setup Requirements

**Dependencies:**
- `puppetlabs/postgresql` (>= 10.0.0 < 11.0.0)
- `aursu/bsys` (>= 0.11.3 < 1.0.0) - provides OS detection and repository management
- `puppetlabs/stdlib` (>= 8.6.0 < 10.0.0)

**System Requirements:**
- Puppet >= 5.5.0
- Supported operating systems (see Limitations section)

### Beginning with lsys_postgresql

The simplest way to use this module is to include the main class:

```puppet
include lsys_postgresql
```

This will:
- Install PostgreSQL with OS-appropriate version
- Configure PostgreSQL to listen on localhost only
- Set up basic authentication
- Install contrib packages

## Usage

### Basic Usage

Install PostgreSQL with default settings:
```puppet
include lsys_postgresql
```

### Custom Network Configuration

Allow remote connections from specific networks:
```puppet
class { 'lsys_postgresql':
  ip_mask_allow_all_users => '192.168.1.0/24',
  listen_addresses        => ['localhost', '192.168.1.100'],
  database_port          => 5432,
}
```

### Disable Repository Management

Use system packages instead of PostgreSQL official repositories:
```puppet
class { 'lsys_postgresql':
  manage_package_repo => false,
  package_version     => undef,
}
```

### Specific Version Installation

Install a specific PostgreSQL version:
```puppet
class { 'lsys_postgresql':
  package_version => '15.13',  # On CentOS 7
  # or
  package_version => '16.9-1.pgdg22+1',  # On Ubuntu 22.04
}
```

### SSL Repository Configuration

Configure repository SSL verification:
```puppet
class { 'lsys_postgresql':
  repo_sslverify => 0,  # Disable SSL verification
}
```

## Reference

### Classes

#### `lsys_postgresql`

Main class for PostgreSQL installation and configuration.

**Parameters:**

##### `manage_dnf_module`
- **Type**: `Boolean`
- **Default**: `true`
- **Description**: Whether to manage DNF module streams on RHEL/CentOS 8+ systems

##### `manage_package_repo`
- **Type**: `Boolean`  
- **Default**: OS-dependent (see lsys_postgresql::params)
- **Description**: Whether to manage PostgreSQL official repositories

##### `package_version`
- **Type**: `Optional[Bsys::PGVersion]`
- **Default**: OS-dependent (see lsys_postgresql::params)
- **Description**: Specific PostgreSQL version to install

##### `ip_mask_allow_all_users`
- **Type**: `String`
- **Default**: `'0.0.0.0/0'`
- **Description**: IP mask for allowing remote database connections in pg_hba.conf

##### `listen_addresses`  
- **Type**: `Lsys_postgresql::PGListen`
- **Default**: `'localhost'`
- **Description**: TCP/IP addresses for PostgreSQL to listen on. Can be string or array of addresses

##### `database_port`
- **Type**: `Variant[Integer, Pattern[/^[0-9]+$/]]`
- **Default**: `5432`
- **Description**: PostgreSQL server port number

##### `repo_sslverify`
- **Type**: `Optional[Integer[0,1]]`
- **Default**: `undef`
- **Description**: SSL verification setting for PostgreSQL repositories (0=disabled, 1=enabled)

#### `lsys_postgresql::params`

Parameter class containing OS-specific defaults.

### Custom Types

#### `Lsys_postgresql::PGAddress`
Valid PostgreSQL address types: IP addresses, hostnames, or special values ('0.0.0.0', '::', '*').

#### `Lsys_postgresql::PGListen`  
PostgreSQL listen address configuration: single address or array of addresses.

### Default Versions by OS

| Operating System | PostgreSQL Version | Repository Management |
|------------------|-------------------|----------------------|
| CentOS 7         | 15.13            | Enabled              |
| CentOS 8+        | 16.8             | Disabled (DNF module)|
| Rocky Linux      | 16.8             | Disabled (DNF module)|
| Ubuntu           | 16.9-1.pgdg{version}+1 | Enabled      |

## Limitations

### Supported Operating Systems

- **Rocky Linux**: 8, 9
- **Ubuntu**: 20.04, 22.04, 24.04
- **CentOS**: 7 (deprecated but supported)

### Known Issues

- **CentOS/RHEL 8+**: Due to modular filtering issues with maintainer repositories, this module uses DNF module streams instead of PostgreSQL.org repositories by default
- **SSL Certificates**: Some corporate environments may require `repo_sslverify => 0` due to certificate chain issues
- **Version Constraints**: PostgreSQL versions are OS-specific and tested combinations. Using custom versions may require additional configuration

### Dependencies

This module requires the `aursu/bsys` module for OS detection and repository management. Ensure this dependency is available in your Puppet environment.

## Development

This module follows standard Puppet development practices:

1. **Testing**: Use PDK for linting, syntax checking, and unit tests
   ```bash
   pdk validate
   pdk test unit
   ```

2. **Contributions**: 
   - Fork the repository
   - Create feature branches  
   - Submit pull requests with tests
   - Follow existing code style

3. **Issues**: Report bugs and feature requests at the [GitHub Issues](https://github.com/aursu/puppet-lsys_postgresql/issues) page

### Development Environment

```bash
# Install PDK
# Clone repository
git clone https://github.com/aursu/puppet-lsys_postgresql.git
cd puppet-lsys_postgresql

# Install dependencies
pdk bundle install

# Run tests
pdk test unit
pdk validate
```

## Release Notes

See [CHANGELOG.md](CHANGELOG.md) for detailed release notes and version history.

## License

This module is licensed under the Apache License, Version 2.0.

## Links

- **Source Code**: https://github.com/aursu/puppet-lsys_postgresql
- **Issues**: https://github.com/aursu/puppet-lsys_postgresql/issues
- **Puppet Forge**: https://forge.puppet.com/modules/aursu/lsys_postgresql
