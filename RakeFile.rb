require 'octokit'
require 'mail'
require 'openssl'
require 'set'
require 'erb'
require 'yaml'
require 'pathname'
require 'rake'

require './Helpers'
require './Config_File'
require './Github'

# configuration
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

#get configuration from config file
config = ConfigFile.read
server = config[:smtp_server_address]
repo = config[:github_repository]

# Github API client
client = Octokit::Client.new :access_token => ENV['MY_PERSONAL_TOKEN']

# mail configuration
options = { address:              config[:smtp_server_address],
            port:                 config[:smtp_server_port],
            domain:               config[:smtp_server_domain],
            user_name:            config[:smtp_server_username],
            password:             config[:smtp_server_password],
            authentication:       config[:smtp_server_authentication],
            enable_starttls_auto:  true  }
Mail.defaults do
  delivery_method :smtp, options
end

# main
repos = Helpers.get_repos(repo)
# Make sure the list has been generated before the multitask call
monitor_list  = Helpers.get_list(repos)

repos.each_with_index{
    |r, index| task monitor_list[index] do
      GitHub.do_monitor(r, config, client)
    end
  }

# Then define the multitask list dependency
multitask :build_parallel => monitor_list