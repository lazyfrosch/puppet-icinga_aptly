require 'spec_helper'
describe 'icinga_aptly' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      context 'with default values for all parameters' do
        it { should contain_class('icinga_aptly') }
      end
    end
  end
end
