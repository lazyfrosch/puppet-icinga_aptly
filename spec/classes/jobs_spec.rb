require 'spec_helper'

describe 'icinga_aptly::jobs' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      context 'with default values' do
        it { is_expected.to contain_class('icinga_aptly::jobs') }
        it { is_expected.to contain_class('icinga_aptly') }

        it do
          is_expected.to contain_file('aptly-cleanup-snapshots')
            .with_path(%r{^/usr/local/bin/})
            .with_mode('0755')
            .with_content(%r{^#!/bin/bash\n})
        end

        it do
          is_expected.to contain_file('aptly-legacy-update-msis')
            .with_path(%r{^/usr/local/bin/})
            .with_mode('0755')
            .with_content(%r{^#!/usr/bin/env ruby\n})
        end

        it do
          is_expected.to contain_file('aptly-legacy-update-rpms')
            .with_path(%r{^/usr/local/bin/})
            .with_mode('0755')
            .with_content(%r{^#!/usr/bin/env ruby\n})
        end

        it do
          is_expected.to contain_file('aptly-process-upload')
            .with_path(%r{^/usr/local/bin/})
            .with_mode('0755')
            .with_content(%r{^#!/usr/bin/env python\n})
        end

        it do
          is_expected.to contain_file('aptly-rpmsign')
            .with_path(%r{^/usr/local/bin/})
            .with_mode('0755')
            .with_content(%r{^#!/usr/bin/env python\n})
        end

        it do
          is_expected.to contain_cron('aptly-cleanup-snapshots')
            .with_command(%r{^/usr/local/bin/aptly-cleanup-snapshots($| )})
            .with_user('aptly')
            .with_hour('*')
            .with_minute('0')
        end

        it do
          is_expected.to contain_cron('aptly-legacy-update-rpms')
            .with_command(%r{^/usr/local/bin/aptly-legacy-update-rpms($| )})
            .with_user('aptly')
            .with_hour('*')
            .with_minute('*/5')
        end

        it do
          is_expected.to contain_cron('aptly-legacy-update-msis')
            .with_command(%r{^/usr/local/bin/aptly-legacy-update-msis($| )})
            .with_user('aptly')
            .with_hour('*')
            .with_minute('*/5')
        end

        it do
          is_expected.to contain_cron('aptly-process-upload')
            .with_command(%r{^/usr/local/bin/aptly-process-upload($| )})
            .with_user('aptly')
            .with_hour('*')
            .with_minute('*/5')
        end
      end
    end
  end
end
