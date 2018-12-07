require 'spec_helper'

describe 'icinga_aptly::content' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      context 'with default values' do
        it { is_expected.to contain_class('icinga_aptly::content') }
        it { is_expected.to contain_class('icinga_aptly') }

        it { is_expected.to contain_package('git') }

        it do
          is_expected.to contain_vcsrepo('aptly web content')
            .with_ensure('latest')
            .with_source('https://github.com/Icinga/packages.icinga.com.git')
            .with_revision('master')
        end
      end
    end
  end
end
