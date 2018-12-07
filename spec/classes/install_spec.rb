require 'spec_helper'

describe 'icinga_aptly::install' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:os_name) { facts[:os]['name'] }
      let(:os_maj) { facts[:os]['release']['major'] }

      let(:helper_packages) { %w[rpm createrepo ruby curl ca-certificates] }

      context 'with default values' do
        it { is_expected.to contain_class('icinga_aptly::install') }
        it { is_expected.to contain_class('icinga_aptly') }

        it do
          if (os_name == 'Debian' && Gem::Version.new(os_maj) < Gem::Version.new('9')) ||
             (os_name == 'Ubuntu' && Gem::Version.new(os_maj) < Gem::Version.new('18.04'))
            is_expected.to contain_package('gnupg')
            is_expected.to contain_package('gpgv')
          else
            is_expected.to contain_package('gnupg1')
            is_expected.to contain_package('gpgv1')
          end
        end

        it do
          helper_packages.each do |pkg|
            is_expected.to contain_package(pkg)
          end
        end

        it { is_expected.to contain_apt__source('aptly') }
        it { is_expected.to contain_package('aptly') }
        it { is_expected.to contain_user('aptly') }

        it { is_expected.to contain_file('aptly home').with_path('/var/lib/aptly') }
        it { is_expected.to contain_file('aptly db').with_path('/var/lib/aptly/db') }
        it { is_expected.to contain_file('aptly public').with_path('/var/lib/aptly/public') }

        it { is_expected.to contain_file('aptly cli').with_path('/usr/local/bin/aptly') }

        it do
          is_expected.to contain_file('aptly.conf')
            .with_path('/var/lib/aptly/.aptly.conf')
            .with_content(%r{"rootDir": "/var/lib/aptly"})
        end
      end
    end
  end
end
