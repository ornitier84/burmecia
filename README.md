# Introduction

What is vagrant-venv?

- Mult-Machine Environment using Vagrant
- Multi-tenancy (environments/*)
- Virtual Machines defined via yaml
- Many vagrant options abstracted via yaml
- Ansible for provisioning (supports puppet manifests as well)

In a nutshell, what you've got here is a portable virtual infrastructure 
leveraging vagrant for machine deployments and ansible/puppet for machine provisionment.

# Preflight

Ok, let's do a preflight check.

Make sure you've installed the following applications **before** proceeding:

- [vagrant](https://www.vagrantup.com/docs/installation/)
- [virtualbox](https://www.virtualbox.org/wiki/Downloads)

Although the project does work fine under Windows cmd, I choose to work in a more posix-friendly commandline environment.

I suggest you install and use either of these:

- [cmder](http://cmder.net) (Full package comes with Git for Windows built-in)
- [Git for Windows](https://git-scm.com/download/win)

The above will provide appropriate program shortcuts for a much better commandline session than cmd (IMO).

# Quick start

Once you've installed the [requirements](#preflight), do as follows:

Activate the sample environment:

```bash
    $ vagrant environment activate contoso
    Activating vagrant environment contoso
    Environment context file is .vagrant/tmp/.environment_context.
```

Initialize the environment inventory file:
```
    $ vagrant Initialize contoso
    Initializing config for environment contoso
    Initializing environment keys for environment contoso
    Done!    
```

Create the environment inventory file:

```
    $ vagrant inventory create contoso
    Writing inventory file environments/contoso/inventory.yaml
    Done!    
```

Last, review your machine states:

```bash

    $ vagrant status
    Current machine states:

    ansible.contoso.com       not created (virtualbox)
    web01.contoso.com         not created (virtualbox)    
```

Start the your virtual machines:

```bash
    $ vagrant up
    Bringing machine 'ansible.contoso.com' up with 'virtualbox' provider...
    Bringing machine 'web01.contoso.com' up with 'virtualbox' provider...
```

# Common tasks

## SSH

To SSH into a virtual machine: `vagrant ssh {{ MACHINE_NAME }}`

e.g. `vagrant ssh ansible.contoso.com`

## Power Off

To power off a virtual machine: `vagrant halt {{ MACHINE_NAME }}`

## Provisionment 

### Ansible

Apply ansible provisionment steps against a virtual machine:<br />
`vagrant provision {{ MACHINE_NAME }} {{ ANSIBLE_CONTROLLER }}`<br />
e.g. `vagrant provision web01.contoso.com ansible.contoso.com`

**Note:** The order of machine names matters when the _ansible_ operational mode is set to 'controller', which is the project default.

As such, the ansible controller node for the environment in question must always be specified last.

Also note that in such a call, any ansible tasks will not execute against the ansible controller itself.

To include the ansible controller in the provisionment steps, you must specify the --include-controller flag in your invocation, as with: `vagrant --include-controller provision ansible.contoso.com`

For more detailed information on the project's provisioner logic, consult [docs/provisioners.md](docs/provisioners.md)

For more usage examples, read [docs/usage.md](docs/usage.md)

# The Environments

All production environments are defined in the environments folder.

Below is the layout included in this repo:

```
environments
| |____
| |____contoso
| | |____config.yaml
| | |____group_vars
| | | |____all
| | | | |____vars.yaml
| | |____host_vars
| | | |ansible.contoso.com.yaml
| | | |web01.contoso.com.yaml
| | |____machines
| | | |____ansible-controllers
| | | | |____ansible.contoso.com.yaml
| | | |____physical-hosts
| | | | |____physical01.contoso.com.yaml
| | | |____web-servers
| | | | |____web01.contoso.com
| | | | | |____playbooks
| | | | | | |____hello.yaml
| | | | |____web01.contoso.com.yaml
```

Note above that machine definitions are simply [YAML](http://yaml.org/) files.

# Machine Definitions

A machine definition consists of a yaml-formatted text file with at minimum the following structure:

```yaml
---
- name: '<%= @machine_name %>'
  config:
    box: '<%= @machine_box %>'
    hostname: '<%= @machine_name %>'
    boot_timeout: <%= @boot_timeout %>
  desktop: <%= $vagrant.defaults.nodes.keys.desktop %>
  provision: <%= $vagrant.defaults.nodes.keys.provision %>
  provider:
    virtualbox:
      modifyvm:
        name: '<%= @machine_name %>'
        natdnshostresolver1: <%= $vagrant.defaults.nodes.keys.natdnshostresolver1 %>
        memory: <%= $environment.sizing[@machine_size].memory %>
        cpus: <%= $environment.sizing[@machine_size].cpus %>
      setextradata:
        VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root: <%= $vagrant.defaults.nodes.keys.VBoxInternal2.SharedFoldersEnableSymlinksCreate.v_root %>
```

Notice the dynamic values encased in `<%= %>`.

This is embedded ruby [ERB](https://ruby-doc.org/stdlib-2.5.3/libdoc/erb/rdoc/ERB.html), and is evaluated as per ERB syntax.

For example, `'<%= @machine_name %>'` ultimately evaluates to intended name of the virtual machine.

For a full list of supported keys, consult [docs/machines.md](docs/machines.md)

See below for more information on Embedded Ruby (ERB):
  
  - [ERB – Ruby Templating](https://ruby-doc.org/stdlib-2.5.3/libdoc/erb/rdoc/ERB.html)
  - [An Introduction to ERB Templating](https://www.stuartellis.name/articles/erb/)

# Provisioners

The project supports the following vagrant provisioners:

- ansible
- local
- puppet
- shell

How you define what provisioners are launched and in what order is done within the Machine Definition file.

For more detailed information on provisioner logic, consult [docs/provisioners.md](docs/provisioners.md)

# Appendix

## Project Settings

All project-specific settings are also defined via YAML/ERB: [etc/config.yaml](etc/config.yaml)

## Softwares

This repository utilizes the below software:

- [Ansible](https://www.ansible.com)
- Supported Hypervisors:
  - [libvirt/kvm](https://libvirt.org/drvqemu.html)
  - [VirtualBox](https://www.virtualbox.org)
- [Vagrant](https://www.vagrantup.com)
  - With the following Plugins:
    - [vagrant-disksize](https://github.com/sprotheroe/vagrant-disksize)
    - [vagrant-hosts](https://github.com/oscar-stack/vagrant-hosts)
    - [vagrant-hostsupdater](https://github.com/cogitatio/vagrant-hostsupdater)
    - [vagrant-libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt) (generally if you're operating from the KVM linux hypervisor, tested on CentOS Linux)
    - [vagrant-vbguest](https://github.com/dotless-de/vagrant-vbguest) (This is for virtualbox)

## Troubleshooting

Error_similar_to: `found unknown escape character while parsing a quoted scalar at line {{ someline }} column {{ somecolumn }}`
  Possible_cause: **You set your VAGRANT_DOTFILE_PATH environment variable as .vagrant\myenvironment which causes a failure in parsing the yaml config file**
  Possible_solution: **Escape the backslash in your path as follows: set VAGRANT_DOTFILE_PATH=.vagrant\\myenvironment**

## License

``vagrant-venv`` is licensed under `MIT License <https://opensource.org/licenses/MIT>`__. You can find the
complete text in ``LICENSE``.
