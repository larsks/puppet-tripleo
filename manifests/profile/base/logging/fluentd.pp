# Copyright 2016 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: tripleo::profile::base::logging::fluentd
#
# FluentD configuration for TripleO
#
# === Parameters
#
# [*step*]
#   (Optional) String. The current step of the deployment
#   Defaults to hiera('step')
#
# [*fluentd_sources*]
#   (Optional) List of dictionaries. A list of sources for fluentd.
#
# [*fluentd_filters*]
#   (Optional) List of dictionaries. A list of filters for fluentd.
#
# [*fluentd_servers*]
#   (Optional) List of dictionaries. A list of destination hosts for
#   fluentd.  Each should be of the form {host=>'my.host.name',
#   'port'=>24224}
#
# [*fluentd_groups*]
#   (Optional) List of strings. Add the 'fluentd' user to these groups.
#
# [*fluentd_secure_forward*]
#   (Optional) Boolean. If true, use the secure_forward plugin.
#
# [*fluentd_pos_file_path*] 
#   (Optional) String.  Path to a directory that will be created 
#   if it does not exist and made writable by the fluentd user.
#
class tripleo::profile::base::logging::fluentd (
  $step = hiera('step', undef),
  $fluentd_sources = undef,
  $fluentd_filters = undef,
  $fluentd_servers = undef,
  $fluentd_groups = undef,
  $fluentd_secure_forward = undef,
  $fluentd_pos_file_path = undef
) {
  if $step == undef or $step >= 3 {
    include ::fluentd

    $forward_plugin = $fluentd_secure_forward ? {
      true    => 'secure_forward',
      default => 'forward'
    }

    if $fluentd_groups {
      user { $::fluentd::config_owner:
        ensure     => present,
        groups     => $fluentd_groups,
        membership => 'minimum',
      }
    }

    if $fluentd_pos_file_path {
      file { $fluentd_pos_file_path:
        ensure => directory,
        owner  => $::fluentd::config_owner,
        group  => $::fluentd::config_group,
        mode   => '0750',
      }
    }

    ::fluentd::plugin { 'rubygem-fluent-plugin-add':
      plugin_provider => 'yum',
    }

    ::fluentd::plugin { 'rubygem-fluent-plugin-elasticsearch':
      plugin_provider => 'yum',
    }

    if $fluentd_sources {
      ::fluentd::config { '100-openstack-sources.conf':
        config => {
          'source' => $fluentd_sources,
        }
      }
    }

    if $fluentd_filters {
      ::fluentd::config { '200-openstack-filters.conf':
        config => {
          'filter' => $fluentd_filters,
        }
      }
    }

    if $fluentd_servers and !empty($fluentd_servers) {
      ::fluentd::config { '300-openstack-matches.conf':
        config => {
          'match' => {
            'type'        => $forward_plugin,
            'tag_pattern' => '**',
            'server'      => $fluentd_servers,
          }
        }
      }
    }
  }
}
