require 'spec_helper'

describe 'Lsys_postgresql::PGListen' do
  it { is_expected.to allow_values('*', '0.0.0.0', '*') }

  it { is_expected.to allow_value([]) }
  it { is_expected.to allow_value(['*', '::', '0.0.0.0', '192.168.0.1']) }
  it { is_expected.to allow_value('localhost') }
  it { is_expected.to allow_value(['domain.tld']) }

  it { is_expected.not_to allow_value('*.domain.tld') }
end
