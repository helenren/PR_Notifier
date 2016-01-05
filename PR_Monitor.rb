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
Helpers.every_n_seconds(config[:github_polling_interval_seconds].to_i) do
  #check if a opened and ready for review pull request is sitting there for a certain period of time or not
  client.pull_requests(repo, :state => 'open').collect {|pull_request| pull_request.number}.each do |pull_request_id|
    open_pull_request = client.pull_request(repo, pull_request_id)

    if (open_pull_request[:title].include? config[:pull_request_ready_indicator])
      # all comments returned by the created time order, the latest one is on the top
      client.pull_request_comments(repo, pull_request_id).sort{|a,b| b[:created_at] <=> a[:created_at]}.each do |pr_comment|
        if (open_pull_request[:user][:login] != pr_comment[:user][:login])
          pr_expired = Helpers.check_expired(pr_comment[:created_at], config[:pull_request_timeout_seconds])
          not_alarmed = true
          alarm_comment_id = 0
          client.issue_comments(repo, pull_request_id).each do |iss_comment|
            content = iss_comment[:body]
            if content.include? config[:notification_comments]
              not_alarmed = false
              alarm_comment_id = iss_comment[:id]
            end
          end

          if (pr_expired and not_alarmed)
            #add expiration comment to the pull request
            client.add_comment(repo, pull_request_id, "#{config[:notification_comments]}")

            #send email for expired pull request
            begin
              Notify.send_notification(config, open_pull_request[:html_url])
            end
          elsif (!pr_expired and !not_alarmed)
            #remove the expiration comment once adding new comments
            client.delete_comment(repo, alarm_comment_id)
          end
          #find the latest comments not from pull request author update the pull request expiration status based on it
          #skip other comments check
          break
        end
        pr_expired = Helpers.check_expired(open_pull_request[:created_at], config[:pull_request_timeout_seconds])
        if (pr_expired)
          not_alarmed = true
          client.issue_comments(repo, pull_request_id).each do |iss_comment|
            content = iss_comment[:body]
            if content.include? config[:notification_comments]
              not_alarmed = false
              break
            end
          end
          if (not_alarmed)
            #add expiration comment to the pull request that has no any comments yet
            client.add_comment(repo, pull_request_id, "#{config[:notification_comments]}")
          end
        end
      end
    end
  end
end
