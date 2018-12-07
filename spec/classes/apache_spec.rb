require 'spec_helper'

describe 'icinga_aptly::apache' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      context 'with default values' do
        it { is_expected.to contain_class('icinga_aptly::apache') }

        it { is_expected.to contain_class('apache') }
        it { is_expected.to contain_class('apache::mod::proxy') }
        it { is_expected.to contain_class('apache::mod::proxy_http') }

        it do
          is_expected.to contain_file('/etc/apache2/aptly-api-auth')
            .with_group('www-data')
            .with_mode('0640')
            .without_content(/^[^#]/)
        end

        it do
          is_expected.to contain_apache__custom_config('aptly-api')
            .with_content(%r{AuthUserFile "/etc/apache2/aptly-api-auth"})
            .with_content(%r{ProxyPass "http://127.0.0.1:8080/api/"})
            .with_content(%r{ProxyPassReverse "http://127.0.0.1:8080/api/"})
        end
      end

      context 'with parameters' do
        let(:params) do
          {
            auth_users: { icinga: 'icinga' },
            auth_userfile: '/var/lib/aptly/.users',
            aptly_backend: 'http://127.0.0.1:8081/api/'
          }
        end

        it do
          is_expected.to contain_file('/var/lib/aptly/.users')
            .with_content(/icinga:icinga/)
        end

        it do
          is_expected.to contain_apache__custom_config('aptly-api')
            .with_content(%r{AuthUserFile "/var/lib/aptly/.users"})
            .with_content(%r{ProxyPass "http://127.0.0.1:8081/api/"})
            .with_content(%r{ProxyPassReverse "http://127.0.0.1:8081/api/"})
        end
      end
    end
  end
end
