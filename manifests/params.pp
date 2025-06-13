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
    'CentOS': {
      if $osmaj == '7' {
        $postgres_version = '15.13'
        $postgres_manage_repo = true
      }
      else {
        $postgres_version = '16.8'
        $postgres_manage_repo = false
      }
    }
    'Rocky': {
      $postgres_version = '16.8'
      $postgres_manage_repo = false
    }
    'Ubuntu': {
      $postgres_version = "16.9-1.pgdg${osmaj}+1"
      $postgres_manage_repo = true
    }
    default: {
      $postgres_version = undef
      $postgres_manage_repo = true
    }
  }
}
