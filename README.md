Trinidad resque extension
-------------------------

Extension to initialize resque as a process under Trinidad's control and integrate resque's console. 
When Trinidad starts up it also starts the resque's workers and the console up.

http://github.com/defunkt/resque

Installation
============

jruby -S gem install trinidad_resque_extension

Configuration
=============

Any of the configuration options that resque needs can be specified in the trinidad's configuration file:

<pre>
---
  extensions:
    resque:
      queues: critical, normal, low   # resque workers
      count:  354                     # number of resque processes, by default 1
      redis_host: 'localhost:6379'    # where redis is running
</pre>

By default, trinidad creates a worker called `trinidad_resque` if we don't
specify anyone, so we can configure the extension through the command line
with all the default options:

<pre>$ jruby -S trinidad -l resque</pre>

The resque console is deployed on /resque but we can disable it with the
option `disable_web`:

<pre>
---
 extensions:
   resque:
     disable_web: true
</pre>

The extension tries to load the tasks from the directory `lib/tasks` but
this parameter can be overrided with the option `path`:

<pre>
---
  extensions:
    resque:
      path: 'tasks_dir'
</pre>

Copyright
=========

Copyright (c) 2011 David Calavera <calavera@apache.org>. See LICENSE for details.
