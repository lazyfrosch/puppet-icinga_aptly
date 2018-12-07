require 'spec_helper'

describe 'icinga_aptly::api' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      context 'with default values' do
        it { is_expected.to contain_class('icinga_aptly::api') }
        it { is_expected.to contain_class('icinga_aptly') }

        it do
          is_expected.to contain_file('aptly-api.service')
            .with_content(%r{ExecStart=/usr/bin/aptly api serve})
            .with_content(%r{-listen=127.0.0.1:8080})
            .with_content(%r{-no-lock})
        end

        it { is_expected.to contain_exec('aptly systemctl daemon-reload').with_refreshonly(true) }

        it { is_expected.to contain_service('aptly-api').with_ensure('running').with_enable(true) }
      end
    end
  end
end
