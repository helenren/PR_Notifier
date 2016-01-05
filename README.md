# PR_Notifier
a service to monitor the expired pull request on github and send remind email to code review group

Environment set up:

1) install the latest version of Ruby: https://www.ruby-lang.org/en/downloads/
2) install the dependencies: mail, openssl, octokit, the command line is: <location Ruby installed>\bin\gem install <dependency>. For example: C:\Ruby22\bin\gem install mail
3) add a system environment variable: MY_PERSONAL_TOKEN, which valure is the person al access token you created on the github

Start the service
cd into the location that the codes located, like c:\PRNotifier, and execue ruby PR_Monitor.rb, like this C:\enlistment\PRNotifier>ruby PR_Monitor.rb

Terminate the service
Ctrl+c
