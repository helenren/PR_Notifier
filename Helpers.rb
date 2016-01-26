module Helpers
# poll staled pull request loop
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

  def Helpers.check_staled(pr_time, timeout)
    (Time.now - pr_time) > timeout.to_i
  end

  def Helpers.get_repos(repo)
     repo.split(",")
  end

  # Generate the list in a method instead of a task
  def Helpers.get_list(repos)
    monitor_list = []
    repos.each_with_index{|r, index| monitor_list << 'task'+index.to_s}
    monitor_list
  end
end