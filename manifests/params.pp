# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include lsys_postgresql::params
class lsys_postgresql::params {
  include bsys::params

  $osname        = $bsys::params::osname
  $osmaj         = $bsys::params::osmaj

  case $osname {
    'CentOS', 'Rocky': {
      if $osname == 'CentOS' and $bsys::params::centos_stream {
        $postgres_version = $osmaj ? {
          '8'     => '15.0',
          default => '15.2',
        }
        $postgres_manage_repo = false
      }
      elsif $osname == 'Rocky' {
        $postgres_version = $osmaj ? {
          '8'     => '15.2',
          default => '15.3',
        }
        $postgres_manage_repo = false
      }
      else {
        $postgres_version = '15.4'
        $postgres_manage_repo = true
      }
    }
    # e.g. Ubuntu/Debian etc
    default: {
      $postgres_version = '15.4'
      $postgres_manage_repo = true
    }
  }
}
