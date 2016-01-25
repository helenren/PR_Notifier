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

def GitHub.do_monitor(repo)
  puts "Monitor #{repo}"
  Helpers.every_n_seconds(config[:github_polling_interval_seconds].to_i) do
    client.pull_requests(repo, :state => 'open').collect {|pull_request| pull_request.number}.each do |pull_request_id|
      open_pull_request = client.pull_request(repo, pull_request_id)
      if (open_pull_request[:title].include? config[:pull_request_ready_indicator])
        # check the pull request is alarmed/signed off or not
        not_alarmed = true
        alarm_comment_id = 0
        signed_off = false
        client.issue_comments(repo, pull_request_id).each do |iss_comment|
          content = iss_comment[:body]
          if content.include? config[:notification_comments]
            not_alarmed = false
            alarm_comment_id = iss_comment[:id]
          elsif content.include? config[:pull_request_signoff_indicator]
            signed_off = true
          end
        end

        if (!signed_off)
          #check if a opened and ready for review pull request is sitting there for a certain period of time or not
          pr_staled = Helpers.check_staled(open_pull_request[:created_at], config[:pull_request_timeout_seconds]);
          client.pull_request_comments(repo, pull_request_id).sort{|a,b| b[:created_at] <=> a[:created_at]}.each do |pr_comment|
            if (open_pull_request[:user][:login] != pr_comment[:user][:login])
              pr_staled = Helpers.check_staled(pr_comment[:created_at], config[:pull_request_timeout_seconds])
              #find the latest comments not from pull request author update the pull request stale status based on it
              #skip other comments check
              break
            end
          end

          # send notification as needed
          if (pr_staled and not_alarmed)
            #add PR is stale comment to the PR
            Notify.send_notifications(client, repo, config, open_pull_request, pull_request_id)
          elsif (!pr_staled and !not_alarmed)
            #remove the PR is stale comment once adding new comments
            client.delete_comment(repo, alarm_comment_id)
          elsif(pr_staled and !not_alarmed)
            #re-send reminder email again every poll
            #Notify.send_email(config, open_pull_request[:html_url])
          end
        end
      end
    end
  end
end