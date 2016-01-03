module Notify
  #send email notification
  def Notify.send_notification(config, pr_link)
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
end
