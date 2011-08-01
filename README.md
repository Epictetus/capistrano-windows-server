capistrano-windows-server
=========================

Deploy Ruby on Rails applications with capistrano to Windows servers

Capistrano is the preferred deploy method for Ruby on Rails apps, but Windows isn't really supported.
We didn't really like having a separate workflow for the projects on that require Windows though,
so this is what we came up with at SciMed.

Currently, only git is supported, but it could potentially support others.
There's plenty of room for improvement here, so feel free to fork and contribute.

### How this is different from a normal capistrano setup

capistrano-windows-server provides a level of convenience for deploying to Windows servers, 
but some things you might expect from a normal capistrano deploy are not possible.
Windows filesystems do not support symlinks, and files cannot be moved or deleted while they are in use (the server is running).

* Your app will deploy directly to #{deploy_to}/current and update in-place.
  When you deploy, capistrano is essentially doing a git pull.
* There is no releases/ directory, and only one copy of your app will be on the server at any time.
  This means that you cannot roll back.
* Git submodules are not yet supported by WindowsGit. Instructions for dealing with that are below.

### Server stack

This gem assumes you are working with the following application stack, but you can modify it to meet your needs.

* Ruby on Rails application
* Mongrel instances proxied behind another web server (Apache + Passenger, nginx)
* Git code repository


Setting up the Windows server
-----------------------------

This section walks you through setting up SSH and Git on the windows server to prepare it for the deploy.
These instruction are for Windows Server 2003. For other versions, YMMV.
Administrative access is required.

* Disable User Access Control. We'll re-enable this later. Reboot if necessary.
  <br><br>
  *Control Panel > Users > Notify never*
  
* Purchase and install WindowsGit from www.windowsgit.com ($9).
  <br><br>
  Yes, you should buy this. I wasted hours trying to get msysgit and COPSSH to work together.
  If your time is worth more than $3/hr, then this is well worth your money.
  
* WindowsGit creates a git user. Make the git user an administrator. This is required, or you will run into
  [this problem](http://stackoverflow.com/questions/4516111/stack-trace-sshd-exe-fatal-error-could-not-load-u-win32-error-1114-copss/4518324).
  <br><br>
  *Administrative Tools > Computer Management > System Tools > Local Users and Groups > Users > git's properties > Member Of > Add "Administrators"*
  
* Open the COPSSH Control Panel
  <br><br>
  *Start Menu > Programs > Copssh > 01 COPSSH Control Panel*
  
* Active the git user for SSH
  <br><br>
  *Users > Add*
  
* *Recommended:* Disallow password authentication, and use SSH key-based authentication

* Import your developers/deployers' public SSH keys
  <br><br>
  *Keys > Import: Paste in public keys; import one at a time.*
  
* Re-enable User Access Control
  <br><br>
  *Control Panel > Users >* (restore previous value)

Now that COPSSH is up and running, ensure that you can SSH into the server as the git user. If you have problems, check the COPSSH event log under the Status tab. Make sure $HOME/.ssh/authorized_keys contains the keys you added.

If you haven't already, set up Ruby and install any gems needed for your application, plus mongrel.
The capistrano recipes in this gem create mongrel Windows services to run your app.
You can use Apache or your web server of choice to proxy for your mongrel instances.


Setting up capistrano for your Rails project
--------------------------------------------

**Rails 2.x**: Add the capistrano-windows-server gem to your Gemfile, and run `bundle`.

    config.gem "capistrano-windows-server", :lib => "capistrano"

**Rails 3.x**: Add the capistrano-windows-server environment.rb, and run `rake gems:install`.

    gem "capistrano-windows-server", :lib => "capistrano"

Set up capistrano as you normally would with `capify`.
The [capistrano wiki](https://github.com/capistrano/capistrano/wiki/2.x-From-The-Beginning) and 
[capistrano handbook](https://github.com/leehambley/capistrano-handbook/blob/master/index.markdown) are helpful.

Set up your config/deploy.rb:

There are a few configuration values that need to be set in your deploy.rb, in addition to your base application configuration.

    require 'capistrano/ext/windows_server'

    set :rails_env, 'production'
    set :user, 'git'
    set :deploy_to, "/cygdrive/c/rails_apps/#{application}" # Deploy to C:\rails_apps\#{application}
    set :mongrel_instances, (1..3)                          # Create 3 mongrel instances
    set :mongrel_instance_prefix, 'mongrel_'                # named mongrel_{1..3}
    set :base_port, 8000                                    # on ports 8000, 8001, 8002
    
    set :ruby_exe_path, '/cygdrive/c/ruby/bin/ruby'         # This should be set to the location where Ruby is installed.

Your final config/deploy.rb might look something like this:

    require 'capistrano/ext/windows_server'

    set :application, "windowsy"
    set :repository, "git@github.com:you/windowsy_rails_app.git"
    set :repository_host_key, "github.com,207.97.227.239 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==" # This is optional and comes from .ssh/known_hosts. It prevents the initial deploy host key verification problems.

    set :branch do
      default_ref = 'master'
      ref = Capistrano::CLI.ui.ask "Ref to deploy (make sure to push the ref first): [#{default_ref}] "
      ref = default_ref if ref.empty?
      ref
    end

    set :rails_env, 'production'
    set :user, 'git'
    set :deploy_to, "/cygdrive/c/rails_apps/#{application}" # Deploy to C:\rails_apps\#{application}
    set :mongrel_instances, (1..3)                          # Create 3 mongrel instances
    set :mongrel_instance_prefix, 'mongrel_'                # named mongrel_{1..3}
    set :base_port, 8000                                    # on ports 8000, 8001, 8002

    set :domain, 'www.windowsy.com'
    role :app, domain
    role :web, domain
    role :db, domain, :primary => true
    

Cleaning up the server before the initial deploy
------------------------------------------------

If you don't already have mongrel Windows services installed for your app, skip this step.

`cap deploy:setup` will create new mongrel Windows services based on the new app location, so you'll need to remove the existing ones.

If you're using the same naming scheme as you have configured in deploy.rb (in our example, mongrel_1 to 3),
then use the deploy:mongrel:remove recipe to remove the services.

    cap deploy:mongrel:remove

Otherwise, remove your old services manually (in a Windows command prompt on the server):

    mongrel service::remove -N old_mongrel_service_name


The initial deploy
------------------

The deploy:setup recipe is a little different for Windows.
In addition to creating the directory structure, it clones your project into #{deploy_to}/current and installs the mongrel Windows services.

    cap deploy:setup

After `cap deploy:setup` runs successfully, it's time to set up the Rails application.
Create or copy in **config/database.yml**, set up the **database**, **install gems**, and anything else you need to do to make the app run.
Testing to make sure the app will start with `rails script/server -e production` is a good idea.

Once it's ready, you can deploy your app for the first time:

    cap deploy:cold

### Submodules

Unfortunately, WindowsGit [does not currently support submodules](https://github.com/SciMed/capistrano-windows-server/issues/1).

If your project uses submodules, there are a few ways you can deal with this.

* Do it by hand - manually clone each submodule after your initial deploy
* Install another git distribution (msysgit, PortableGit), and run git submodule init/update in your project directory
* Pull the missing files out of another git distribution (msysgit, PortableGit) and copy them to C:\Program Files\ICW\bin .
  If you go this route, please document the process on [this issue](https://github.com/SciMed/capistrano-windows-server/issues/1),
  so we can update this documentation.


Which cap tasks are available?
------------------------------

As usual, you can use `cap -T` for a full list of capistrano tasks.

The following default capistrano tasks are supported:

* `cap deploy` - Updates the code on the server (essentially just a git pull in the current/ directory)
* `cap deploy:cold` - Deploy and start the server
* `cap deploy:start` `cap deploy:stop` `cap deploy:restart` - Stop and start the mongrel services
* `cap deploy:migrate` - Run migrations
* `cap deploy:migrations` - Deploy and run migrations
* `cap deploy:update` - Updates the code without restarting the server
* `cap deploy:update_code` - Now an alias for deploy:update
* `cap deploy:upload` - Upload files to the server
* `cap invoke` - Run a command on the server specified by COMMAND
* `cap shell` - Open a Begin an interactive Capistrano session

The following new tasks were added:

* `cap deploy:mongrel:setup` - Create mongrel services
* `cap deploy:mongrel:remove` - Remove mongrel services
* `cap rake` - Run a rake task, specified by COMMAND. eg: cap rake COMMAND="gems:install"

The following tasks will later be fixed:

* `cap deploy:check`
* `cap deploy:pending`
* `cap deploy:pending:diff`
* `cap deploy:web:enable`
* `cap deploy:web:disable`

The following tasks were removed:

* `cap deploy:cleanup`
* `cap deploy:rollback`
* `cap deploy:symlink`


Contributing to capistrano-windows-server
-----------------------------------------

This gem was created to work on our systems and has not yet been tested on a wide range of systems.
We would love if you contribute back changes that you make to make it work for you.
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution


Copyright
---------

Copyright (c) 2011 SciMed Solutions, Inc. See LICENSE.txt for further details.
