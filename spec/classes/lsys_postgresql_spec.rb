# frozen_string_literal: true

require 'spec_helper'

describe 'lsys_postgresql' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_class('postgresql::server')
          .with_listen_addresses('localhost')
      }

      context 'with multiple listen addresses' do
        let(:params) do
          {
            listen_addresses: ['localhost', '10.10.10.1'],
          }
        end

        it {
          is_expected.to contain_class('postgresql::server')
            .with_listen_addresses('localhost,10.10.10.1')
        }
      end

      case os
      when %r{^centos-8}, %r{^rocky}
        it {
          is_expected.to contain_package('postgresql-server')
            .with_ensure('16.8')
            .with_name('postgresql-server')
        }
      when %r{^centos-7}
        it {
          is_expected.to contain_yumrepo('yum.postgresql.org')
            .with_baseurl(%r{^https://download.postgresql.org/pub/repos/yum/15/redhat/rhel-\$releasever-\$basearch})
            .that_notifies('Exec[yum-reload-9c247b8]')
        }

        it {
          is_expected.to contain_package('postgresql-server')
            .with_ensure('15.13')
            .with_name('postgresql15-server')
        }

        it {
          is_expected.to contain_package('libzstd')
            .that_comes_before('Package[postgresql-server]')
            .that_requires('Package[epel-release]')
        }

        it {
          is_expected.to contain_file('/etc/pki/rpm-gpg/RPM-GPG-KEY-PGDG-15')
            .with_content(%r{mQGNBGWBsHEBDACzg9nBu9GXrquREAEVTObf6k3YIWagkv1qlX61dqQpyx8XT36A})
        }
      else
        it {
          is_expected.to contain_package('postgresql-server')
            .with_ensure(%r{^16\.9})
        }
      end
    end
  end
end
