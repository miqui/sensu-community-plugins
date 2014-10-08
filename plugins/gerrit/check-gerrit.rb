#!/usr/bin/env ruby
#
# Checks gerrit code review status
# ===
#
# DESCRIPTION:
#   This plugin checks if gerrit code review is online based on using its
#   REST API.
#   https://gerrit-review.googlesource.com/Documentation/rest-api-config.html#get-version
#
# OUTPUT:
#
#
# PLATFORMS:
#   all
#
# DEPENDENCIES:
#   sensu-plugin Ruby gem
#   rest-client Ruby gem
#
#  Miguel Quintero <migmaqer@gmail.com>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'rest-client'
require 'json'

class GerritHealth < Sensu::Plugin::Check::CLI

  option :server,
    :description => 'Elasticsearch server',
    :short => '-s SERVER',
    :long => '--server SERVER',
    :default => 'localhost'

  option :warn,
    :short => '-w N',
    :long => '--warn N',
    :description => 'Heap used in bytes WARNING threshold',
    :proc => proc {|a| a.to_i },
    :default => 0

  option :crit,
    :short => '-c N',
    :long => '--crit N',
    :description => 'Heap used in bytes CRITICAL threshold',
    :proc => proc {|a| a.to_i },
    :default => 0

  def get_resource(resource)
    begin
      r = RestClient::Resource.new("http://#{config[:server]}:9200/#{resource}", :timeout => 45)
      JSON.parse(r.get)
    rescue Errno::ECONNREFUSED
      warning 'Connection refused'
    rescue RestClient::RequestTimeout
      warning 'Connection timed out'
    rescue JSON::ParserError
      warning 'Gerrit REST API returned invalid JSON'
    end
  end

  def get_version
    stats = get_resource('/config/server/version')
    node = stats['nodes'].keys.first
    begin
      stats['nodes'][node]['jvm']['mem']['heap_used_in_bytes']
    rescue
      warning 'Failed to obtain gerrit version'
    end
  end

  def run
    heap_used = get_heap_used
    message "Heap used in bytes #{heap_used}"
    if heap_used >= config[:crit]
      critical
    elsif heap_used >= config[:warn]
      warning
    else
      ok
    end
  end

end
