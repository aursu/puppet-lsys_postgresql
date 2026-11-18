# frozen_string_literal: true

require 'spec_helper'

describe 'lsys_postgresql::database' do
  let(:title) { 'app' }
  let(:pre_condition) { 'include lsys_postgresql' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with defaults' do
        let(:params) { { password: 'secret' } }

        it { is_expected.to compile.with_all_deps }

        it {
          is_expected.to contain_postgresql__server__db('app')
            .with_user('app')
            .with_owner('app')
        }

        it { is_expected.to contain_postgresql__server__role('app') }

        it {
          is_expected.to contain_postgresql__server__pg_hba_rule('app: app from 127.0.0.1/32')
            .with(
              type: 'host',
              database: 'app',
              user: 'app',
              address: '127.0.0.1/32',
              auth_method: 'scram-sha-256',
              order: 50,
            )
        }
      end

      context 'with a Sensitive password, own role name and two addresses' do
        let(:params) do
          {
            password: sensitive('secret'),
            user: 'app_rw',
            client_addresses: ['127.0.0.1/32', '10.0.0.0/24'],
          }
        end

        it { is_expected.to compile.with_all_deps }

        it {
          is_expected.to contain_postgresql__server__db('app')
            .with_user('app_rw')
            .with_owner('app_rw')
        }

        it { is_expected.to contain_postgresql__server__pg_hba_rule('app: app_rw from 127.0.0.1/32') }
        it { is_expected.to contain_postgresql__server__pg_hba_rule('app: app_rw from 10.0.0.0/24') }
      end

      context 'with no client addresses' do
        let(:params) { { password: 'secret', client_addresses: [] } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_postgresql__server__pg_hba_rule('app: app from 127.0.0.1/32') }
      end
    end
  end
end
