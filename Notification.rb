module Notify
  #send email notification
  def Notify.send_email(config, pr_link)
    begin
      email_body = config[:notification_body]
      Mail.deliver do
        from     config[:notification_sender_email]
        to       config[:notification_receivers_email]
        subject  "#{config[:notification_subject]}"
        text_part do
          body "#{config[:notification_body]}: #{pr_link}"
        end
      end
    end
  end

  def Notify.send_notifications(client, repo, config, pr, pr_id)
    # add comments on github for expired pull request
    client.add_comment(repo, pr_id, "#{config[:notification_comments]}")

    #send email for expired pull request
    send_email(config, pr[:html_url])
  end
end
