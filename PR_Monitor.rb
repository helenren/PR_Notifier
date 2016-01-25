require 'octokit'
require 'mail'
require 'openssl'
require 'set'
require 'erb'
require 'yaml'
require 'pathname'

require './Helpers'
require './Notification'
require './Config_File'

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
puts "all repos are monitored are: #{repos}"
repos.each { |r| GitHub.do_monitor(r) }