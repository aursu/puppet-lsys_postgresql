# @summary PostgreSQL server installation
#
# PostgreSQL server installation
#
# @example
#   include lsys_postgresql
#
# @param ip_mask_allow_all_users
#   Overrides PostgreSQL defaults for remote connections. By default, PostgreSQL
#   does not allow database user accounts to connect via TCP from remote
#   machines. If you'd like to allow this, you can override this setting. Set to
#   '0.0.0.0/0' to allow database users to connect from any remote machine, or
#   '192.168.0.0/1' to allow connections from any machine on your local '192.168'
#   subnet. Default value: '127.0.0.1/32'.
#
# listen_addresses (string)
#   Specifies the TCP/IP address(es) on which the server is to listen for connections
#   from client applications. The value takes the form of a comma-separated list
#   of host names and/or numeric IP addresses. The special entry * corresponds
#   to all available IP interfaces. The entry 0.0.0.0 allows listening for all
#   IPv4 addresses and :: allows listening for all IPv6 addresses. If the list
#   is empty, the server does not listen on any IP interface at all, in which case
#   only Unix-domain sockets can be used to connect to it. If the list is not empty,
#   the server will start if it can listen on at least one TCP/IP address. A warning
#   will be emitted for any TCP/IP address which cannot be opened. The default
#   value is localhost, which allows only local TCP/IP “loopback” connections to
#   be made.
#
class lsys_postgresql (
  Boolean $manage_dnf_module = true,
  Boolean $manage_package_repo = $lsys_postgresql::params::postgres_manage_repo,
  # https://www.postgresql.org/support/versioning/
  Optional[Bsys::PGVersion] $package_version = $lsys_postgresql::params::postgres_version,
  String $ip_mask_allow_all_users = '0.0.0.0/0',
  Lsys_postgresql::PGListen $listen_addresses = 'localhost',
  Variant[Integer, Pattern[/^[0-9]+$/]] $database_port = 5432,
  Optional[Integer[0,1]] $repo_sslverify = undef,
) inherits lsys_postgresql::params {
  include bsys::params
  include bsys::repo

  if $package_version {
    $version_data = split($package_version, '[.]')
    $major_version = $version_data[0]
    $minor_version = $version_data[1]

    $repo_version = $major_version ? {
      '9' => $minor_version ? {
        default => "9.${minor_version}",
      },
      default => $major_version,
    }
  }
  else {
    $repo_version = undef
  }

  # we can not use maintainer's repo on CentOS 8+ due to issue:
  # All matches were filtered out by modular filtering for argument
  # Therefore we use postgresql:12 dnf module stream
  $_manage_dnf_module = $bsys::params::osfam ? {
    'RedHat' => $bsys::params::manage_dnf_module,
    default => false,
  }

  # if DNF system and we want to manage DNF module it and it is manageable
  if $_manage_dnf_module and $manage_dnf_module {
    class { 'postgresql::globals':
      manage_package_repo => $manage_package_repo,
      manage_dnf_module   => true,
      version             => $repo_version,
      service_provider    => 'systemd',
    }
  }
  else {
    class { 'postgresql::globals':
      manage_package_repo => $manage_package_repo,
      version             => $repo_version,
      service_provider    => 'systemd',
    }
  }

  case $bsys::params::osfam {
    'RedHat': {
      if $manage_package_repo {
        include bsys::repo::epel

        include postgresql::repo::yum_postgresql_org
        $gpg_key_path = $postgresql::repo::yum_postgresql_org::gpg_key_path

        if $bsys::params::osmaj == '7' {
          File <| title == $gpg_key_path |> {
            content => file('lsys_postgresql/PGDG-RPM-GPG-KEY-RHEL7'),
          }
        }

        if $repo_sslverify {
          Yumrepo <| title == 'yum.postgresql.org' |> {
            sslverify => $repo_sslverify,
          }

          Yumrepo <| title == 'pgdg-common' |> {
            sslverify => $repo_sslverify,
          }
        }

        file {
          default: mode => '0600';
          '/etc/yum.repos.d/yum.postgresql.org.repo': ;
          '/etc/yum.repos.d/pgdg-common.repo': ;
        }

        if $bsys::params::osmaj == '7' {
          package { 'libzstd':
            ensure  => 'installed',
            require => Class['bsys::repo::epel'],
            before  => Class['postgresql::server'],
          }
        }

        Class['postgresql::repo::yum_postgresql_org'] ~> Class['bsys::repo']
      }
      else {
        # remove unmanaged repositories
        file {
          default:
            ensure => 'absent',
            notify => Class['bsys::repo'],
            ;
          '/etc/yum.repos.d/yum.postgresql.org.repo': ;
          '/etc/yum.repos.d/pgdg-common.repo': ;
        }
      }
    }
    'Debian': {
      if $manage_package_repo {
        Class['postgresql::repo::apt_postgresql_org'] ~> Class['bsys::repo']
      }
    }
    default: {}
  }

  $listen_addresses_string = $listen_addresses ? {
    Array[Lsys_postgresql::PGAddress] => join($listen_addresses, ','),
    default => $listen_addresses,
  }

  class { 'postgresql::server':
    package_ensure          => $package_version,
    ip_mask_allow_all_users => $ip_mask_allow_all_users,
    listen_addresses        => $listen_addresses_string,
    port                    => $database_port + 0,
  }
  contain postgresql::server

  class { 'postgresql::server::contrib': }
}
