module Helpers
# poll expired pull request loop
  def Helpers.every_n_seconds(n)
    begin
      loop do
        before = Time.now
        yield
        interval = n-(Time.now-before)
        sleep(interval) if interval > 0
      end
  end
end

  def Helpers.check_expired(pr_created_time, timeout)
    (Time.now - pr_created_time) > timeout.to_i
  end
end