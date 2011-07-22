configuration = Capistrano::Configuration.respond_to?(:instance) ?
  Capistrano::Configuration.instance(:must_exist) :
  Capistrano.configuration(:must_exist)

configuration.load do
  set :scm, :git
  set :deploy_via, :remote_cache
  #set :git_enable_submodules, false # Git submodules not supported on windows
  set :shared_dir, "."
  set :repository_cache, "current"
  set :scm_verbose, true
  set :use_sudo, false

  namespace :deploy do
    desc "Update the code on the server by doing a git pull in the current/ directory"
    task :update do
      # update_repository_cache will attempt to clean out the repository; we must prevent that.
      # /bin/git below is where www.windowsgit.com's windows git/ssh installation puts the git executable.
      # This creates a git proxy that goes in $PATH before /bin, which will filter out any `git clean` commands.
      run "mkdir -p '#{shared_path}/bin'"
      run <<-RUN
        echo 'if [ "$1" != "clean" ]; then /bin/git $*; fi' > "#{shared_path}/bin/git.exe"
      RUN
      alter_path_cmd = "export PATH=#{shared_path}/bin:$PATH # Required for capistrano-windows-server"
      run <<-RUN
        if ! grep '#{alter_path_cmd}' ~/.bashrc > /dev/null; then echo '#{alter_path_cmd}' >> ~/.bashrc; fi
      RUN

      strategy.send 'update_repository_cache'
    end

    desc "An alias for deploy:update"
    task :update_code do
      update
    end

    desc <<-DESC
      Prepares one or more servers for deployment. Before you can use any \
      of the Capistrano deployment tasks with your project, you will need to \
      make sure all of your servers have been prepared with `cap deploy:setup'. When \
      you add a new server to your cluster, you can easily run the setup task \
      on just that server by specifying the HOSTS environment variable:

      $ cap HOSTS=new.server.com deploy:setup

      It is safe to run this task on servers that have already been set up; it \
      will not destroy any deployed revisions or data.
    DESC
    task :setup do
      dirs = [deploy_to]
      run "mkdir -p #{dirs.join(' ')} && chmod g+w #{dirs.join(' ')}"

      if exists?(:repository_host_key)
        run "if ! grep '#{repository_host_key}' ~/.ssh/known_hosts > /dev/null; then echo '#{repository_host_key}' >> ~/.ssh/known_hosts; fi"
      end
    end

    # Remove tasks that are not appropriate on Windows
    %w(finalize_update symlink cleanup).each do |removed_task|
      task removed_task do; end
    end
    namespace :rollback do
      %w(code default).each do |removed_task|
        task removed_task do; end
      end
    end

    desc "Run pending migrations"
    task :migrate do
      set :rake_cmd, "#{ruby_exe_path} -e \"require 'rubygems'; gem 'rake', '>= 0'; load Gem.bin_path('rake', 'rake', '>= 0')\""
      run "cd #{current_path} && #{rake_cmd} db:migrate RAILS_ENV=#{rails_env}"
    end

    desc "Start mongrel"
    task :start do
      mongrel_instances.each do |n|
        run "net start #{mongrel_instance_prefix}#{n}"
      end
    end

    desc "Stop mongrel"
    task :stop do
      mongrel_instances.each do |n|
        run "net stop #{mongrel_instance_prefix}#{n}"
      end
    end

    desc "Restart mongrel"
    task :restart do
      mongrel_instances.each do |n|
        run "net stop #{mongrel_instance_prefix}#{n}"
        run "net start #{mongrel_instance_prefix}#{n}"
      end
    end

    namespace :mongrel do
      desc "Create mongrel services"
      task :setup do
        mongrel_instances.each do |n|
          run "cd #{current_path} && #{mongrel_cmd} service::install -e #{rails_env} -N #{mongrel_instance_prefix}#{n} -p #{base_port + n - mongrel_instances.first}"
          run %Q(sc.exe config "#{mongrel_instance_prefix}#{n}" start= auto)
        end
      end

      desc "Remove mongrel services"
      task :remove do
        set :mongrel_cmd, "#{ruby_exe_path} -e \"require 'rubygems'; gem 'mongrel', '>= 0'; load Gem.bin_path('mongrel', 'mongrel_rails', '>= 0')\""
        mongrel_instances.each do |n|
          run "#{mongrel_cmd} service::remove -N #{mongrel_instance_prefix}#{n}"
        end
      end

    end

  end

  desc "Run a rake command in COMMAND"
  task :rake do
    raise "Specify the command with COMMAND='some:task with_arguments'" unless ENV['COMMAND']
    set :rake_cmd, "#{ruby_exe_path} -e \"require 'rubygems'; gem 'rake', '>= 0'; load Gem.bin_path('rake', 'rake', '>= 0')\""
    run "cd #{current_path} && #{rake_cmd} #{ENV['COMMAND']} RAILS_ENV=#{rails_env}"
  end

  after 'deploy:setup', 'deploy:update_code'
  after 'deploy:setup', 'deploy:mongrel:setup'

end
