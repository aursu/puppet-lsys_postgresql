# @summary A database with its own login role and explicit pg_hba lines
#
# Creates the role and the database through `postgresql::server::db` and writes
# one `host` line to pg_hba.conf per client address. The lines are ordered
# before the generic rules that `postgresql::server` writes (orders 100 and
# 101), so the database keeps working if `ip_mask_allow_all_users` is narrowed
# later.
#
# The password is passed on as Sensitive and hashed by puppetlabs-postgresql
# with the server's `password_encryption` (scram-sha-256 on PostgreSQL 14 and
# later).
#
# The PostgreSQL server must be declared on the node (`lsys_postgresql`); this
# define does not declare it, so that nodes declaring the class with
# parameters keep working.
#
# @example A database for an application on the same host
#   lsys_postgresql::database { 'app':
#     password => Sensitive('secret'),
#   }
#
# @param password
#   Password of the login role. A plain String is wrapped into Sensitive.
#
# @param user
#   Login role, owner of the database. Defaults to the title.
#
# @param dbname
#   Database name. Defaults to the title.
#
# @param client_addresses
#   One pg_hba `host` line per address (CIDR). An empty array writes none:
#   the role can then only connect through rules written elsewhere.
#
# @param auth_method
#   pg_hba authentication method for these lines.
#
# @param hba_order
#   Order of the lines in pg_hba.conf; below 100 they come before the generic
#   rules of `postgresql::server`.
#
# @param encoding
#   Database encoding; the server default when not set.
#
# @param locale
#   Database locale; the server default when not set.
#
define lsys_postgresql::database (
  Variant[String[1], Sensitive[String[1]]] $password,
  String[1] $user = $title,
  String[1] $dbname = $title,
  Array[Postgresql::Pg_hba_rule_address] $client_addresses = ['127.0.0.1/32'],
  Enum['scram-sha-256', 'md5'] $auth_method = 'scram-sha-256',
  Integer[5, 99] $hba_order = 50,
  Optional[String[1]] $encoding = undef,
  Optional[String[1]] $locale = undef,
) {
  $_password = $password ? {
    Sensitive => $password,
    default   => Sensitive($password),
  }

  # The role owns the database: since PostgreSQL 15 only the database owner may
  # create objects in the `public` schema (GRANT ALL on the database is not
  # enough). For an existing database puppetlabs-postgresql runs ALTER DATABASE
  # ... OWNER TO.
  postgresql::server::db { $dbname:
    user     => $user,
    owner    => $user,
    password => $_password,
    encoding => $encoding,
    locale   => $locale,
  }

  $client_addresses.each |$address| {
    postgresql::server::pg_hba_rule { "${dbname}: ${user} from ${address}":
      type        => 'host',
      database    => $dbname,
      user        => $user,
      address     => $address,
      auth_method => $auth_method,
      order       => $hba_order,
      description => "${user} to ${dbname} from ${address}",
    }
  }
}
