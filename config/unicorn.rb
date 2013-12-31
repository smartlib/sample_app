# unicorn_rails -c /home/ruby/sample/current/config/unicorn.rb -E production -D
module Rails
  class <<self
    def root
      File.expand_path(__FILE__).split('/')[0..-3].join('/')
    end
  end
end
rails_env = ENV['RAILS_ENV'] || 'production'

working_directory (rails_env == 'production' ? "/home/ruby/sample/current" : Rails.root)
worker_processes  (rails_env == 'production' ? 10 : 4)
preload_app       true
timeout           30

if rails_env == 'production'
  listen      5000
  listen      '/tmp/unicorn_padrino.sock', :backlog => 2048

  rails_root  = Rails.root
  pid         "/home/ruby/sample/shared/pids/unicorn_padrino.pid"
  stderr_path "/home/ruby/sample/shared/log/unicornerr.log"
  stdout_path "/home/ruby/sample/shared/log/unicornout.log"
else
  listen      8080

  rails_root  = Rails.root
  pid         "#{rails_root}/tmp/pids/unicorn_padrino.pid"
  stderr_path "#{rails_root}/log/unicornerr.log"
  stdout_path "#{rails_root}/log/unicornout.log"
end


GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)

before_fork do |server, worker|
  ActiveRecord::Base.connection.disconnect!

  ##
  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # Using this method we get 0 downtime deploys.

  old_pid = Rails.env.production? ? "/home/ruby/sample/shared/pids/unicorn_padrino.pid.oldbin" :
                                    "#{Rails.root}/tmp/pids/unicorn_padrino.pid.oldbin"

  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end


after_fork do |server, worker|
  ActiveRecord::Base.establish_connection

  worker.user('rails', 'rails') if Process.euid == 0 && rails_env == 'production'
end
