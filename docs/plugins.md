Adhoc Vagrant Plugins
-----------------

I've created a set of custom commands available to vagrant.

These commands are exposed through ad-hoc vagrant plugins created from ([lib/commands](lib/commands)) via the [.vagrantplugins](.vagrantplugins) file,
and are but simple ruby scripts.

- [.vagrantplugins](.vagrantplugins)
- [lib/commands](lib/commands)

The scripts execute within the vagrant context, so it is easy to create automation that plays nice with vagrant.

For example, the `environment` command ([lib/commands/environment.rb](lib/commands/environment.rb)) allows you to manage your vagrant environments.

Simply run `vagrant environment -h` to review usage information.

Lastly, do consider one caveat: the ``.vagrantplugins`` file is not officially supported by Hashicorp, but remains a means to define these ad-hoc plugins.
