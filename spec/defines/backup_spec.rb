# frozen_string_literal: true

require 'spec_helper'

describe 'lsys_postgresql::backup' do
  let(:title) { 'app' }
  let(:pre_condition) do
    <<~PUPPET
      restic::repository { 'postgres':
        repository => '/var/backups/restic/postgres',
        password   => 'secret',
      }
    PUPPET
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with defaults' do
        let(:params) { { repository: 'postgres' } }

        it { is_expected.to compile.with_all_deps }

        it {
          is_expected.to contain_restic__job('postgres-app')
            .with(
              repository: 'postgres',
              command: ['/usr/sbin/runuser', '-u', 'postgres', '--', '/usr/bin/pg_dump', '--format=custom', 'app'],
              stdin_filename: 'app.dump',
              snapshot_tag: 'app',
              keep: { 'hourly' => 24, 'daily' => 7 },
              minute: '0',
              hour: '*',
            )
        }
      end

      context 'with own database name, schedule and retention' do
        let(:params) do
          {
            repository: 'postgres',
            dbname: 'puppetdb',
            minute: '47',
            keep: { 'daily' => 14 },
          }
        end

        it { is_expected.to compile.with_all_deps }

        it {
          is_expected.to contain_restic__job('postgres-puppetdb')
            .with_command(['/usr/sbin/runuser', '-u', 'postgres', '--', '/usr/bin/pg_dump', '--format=custom', 'puppetdb'])
            .with_snapshot_tag('puppetdb')
            .with_minute('47')
            .with_keep('daily' => 14)
        }
      end
    end
  end
end
