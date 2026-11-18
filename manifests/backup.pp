# @summary Scheduled pg_dump of one database into a restic repository
#
# Runs pg_dump as the operating system user `postgres` over the local socket
# (peer authentication), so the backup needs no database password. The dump
# (custom format by default, restorable with pg_restore) is streamed into
# restic as one file per snapshot, tagged with the database name; retention
# (`restic forget`) is scoped to that tag, so several databases can share one
# repository.
#
# The restic repository is declared by the caller (`restic::repository`),
# which keeps its location, password and any off-site copy out of this module.
#
# @example Hourly dump at minute 47 into a local repository
#   restic::repository { 'postgres':
#     repository => '/var/backups/restic/postgres',
#     password   => Sensitive('secret'),
#   }
#   lsys_postgresql::backup { 'app':
#     repository => 'postgres',
#     minute     => '47',
#   }
#
# @param repository
#   Title of the `restic::repository` to write to.
#
# @param dbname
#   Database to dump. Defaults to the title.
#
# @param os_user
#   Operating system user pg_dump runs as (peer authentication).
#
# @param pg_dump
#   Path of pg_dump. On Debian and Ubuntu `/usr/bin/pg_dump` is the
#   postgresql-common wrapper that picks the installed cluster version.
#
# @param dump_options
#   Options passed to pg_dump before the database name.
#
# @param runuser
#   Path of runuser, used to switch to `os_user`.
#
# @param keep
#   Retention, keyed by restic keep-* class.
#
# @param schedule_provider
#   `cron` or `systemd_timer`, as in `restic::job`.
#
# @param minute
#   Cron minute.
#
# @param hour
#   Cron hour.
#
# @param crontab
#   Full cron schedule string; overrides `minute` and `hour` when set.
#
# @param on_calendar
#   systemd OnCalendar expression for `systemd_timer`.
#
# @param enable
#   Whether the job is scheduled.
#
define lsys_postgresql::backup (
  String[1] $repository,
  String[1] $dbname = $title,
  String[1] $os_user = 'postgres',
  Stdlib::Absolutepath $pg_dump = '/usr/bin/pg_dump',
  Array[String[1]] $dump_options = ['--format=custom'],
  Stdlib::Absolutepath $runuser = '/usr/sbin/runuser',
  Hash[Enum['last', 'hourly', 'daily', 'weekly', 'monthly', 'yearly'], Integer] $keep = {
    'hourly' => 24,
    'daily'  => 7,
  },
  Enum['cron', 'systemd_timer'] $schedule_provider = 'cron',
  String[1] $minute = '0',
  String[1] $hour = '*',
  Optional[String[1]] $crontab = undef,
  String[1] $on_calendar = '*-*-* *:00:00',
  Boolean $enable = true,
) {
  restic::job { "postgres-${dbname}":
    repository        => $repository,
    command           => [$runuser, '-u', $os_user, '--', $pg_dump] + $dump_options + [$dbname],
    stdin_filename    => "${dbname}.dump",
    snapshot_tag      => $dbname,
    keep              => $keep,
    schedule_provider => $schedule_provider,
    minute            => $minute,
    hour              => $hour,
    crontab           => $crontab,
    on_calendar       => $on_calendar,
    enable            => $enable,
  }
}
