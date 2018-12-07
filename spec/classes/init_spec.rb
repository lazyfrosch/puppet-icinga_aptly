require 'spec_helper'

describe 'icinga_aptly' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      context 'with default values' do
        it { is_expected.to contain_class('icinga_aptly') }
        it { is_expected.to contain_class('icinga_aptly::params') }

        it { is_expected.to contain_class('icinga_aptly::install') }
        it { is_expected.to contain_class('icinga_aptly::api') }
        it { is_expected.to contain_class('icinga_aptly::content') }
        it { is_expected.to contain_class('icinga_aptly::jobs') }
      end

      context 'with manage_apache' do
        let(:params) { { manage_apache: true } }

        it { is_expected.to contain_class('icinga_aptly::apache') }
      end
    end
  end
end
