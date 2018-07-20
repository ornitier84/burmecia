**Quick links** [TL;DR] | [Install Using Bootstrap Script] | [Purpose] | [Overview]

## TL;DR

- Mult-Machine Environment using Vagrant
- All nodes defined via yaml
- Ansible for provisioning

[Install Using Bootstrap Script]: #install-using-bootstrap-script

### Install Using Bootstrap Script

**If you're on Windows**, you have two options to satisfy all project requirements:

1. You can clone this repo and run the bootstrap script [scripts\windows.bootstrap.bat](scripts\windows.bootstrap.bat) to have everything installed using [chocolatey](https://chocolatey.org/)

```bat
cmd /c scripts\windows.bootstrap.bat
```

[Using the bootstrap script]: #using-the-bootstrap-script

**OR** You can go the manual route.

#### Manually

1. You can manually install the project requirements:
    1. Install [git](https://git-scm.com/download/win)
    1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads). 
    1. Install [Vagrant](https://www.vagrantup.com/docs/installation/)
    1. Start an Elevated Command Prompt (CMD) (Runas Admin)
    1. Update your PATH variable `SET PATH=%PATH%;C:\HashiCorp\Vagrant\embedded\mingw64\bin`
    1. Clone this repo and run `ruby C:\HashiCorp\Vagrant\embedded\mingw64\bin\rake init` to initialize and install any project requirements

```sh
git$ git clone https://github.com/berttejeda/vagrant-venv.git
git$ cd vagrant-environments
git/vagrant-environments$ SET PATH=C:\HashiCorp\Vagrant\embedded\mingw64\bin;%PATH%
git/vagrant-environments$ ruby C:\HashiCorp\Vagrant\embedded\mingw64\bin\rake init
```  
[rake]: #rake

A super-quick set of vagrant commands to get you moving: 

[Manually]: #manually

**Vagrant Commands**

- Check all machine states
  - `vagrant status`
- Boot up a virtual machine
  - `vagrant up {{ MACHINE_NAME }}`
- SSH into a virtual machine
  - `vagrant ssh {{ MACHINE_NAME }}`
- Power Off a virtual machine
  - `vagrant halt {{ MACHINE_NAME }}`
- Apply provisionment steps (ansible) against virtual machine
  - `vagrant provision {{ MACHINE_NAME }}`

**Note:** In the case of Windows hosts, ansible runs from within the VM. This is because ansible is not yet fully supported on Windows platforms. The method by which this is accomplished is through the use of a helper script. See [scripts/windows.ansible-playbook.sh](scripts/windows.ansible-playbook.sh)

That's it for the TL;DR. The following sections cover the project details at greater length.

[TL;DR]: #tldr 

## Purpose

This project leverages several technologies to unify management of some of the biggest moving parts of a modern technology infrastructure:

* Cloud (planned)
* Microservices
* Physical/BareMetal hosts (planned)
* Virtual hosts

In a nutshell, what you've got here is a portable virtual infrastructure leveraging vagrant for machine deployments and ansible and/or puppet for machine provisionment.

**Contents** [Overview] | [Getting started] | [Contributing] 

[Purpose]: #Purpose
## Overview

In order to achieve the seamless management described above, we make use of:

- [Ansible](https://www.ansible.com)
- [Vagrant](https://www.vagrantup.com)

### The Environments

All production environments are defined in the environments folder, which adheres to this directory layout:

```
environments/
|____{{ ENVIRONMENT_NAME }}
| |____group_vars
| | |____all.yaml
| |____hosts
| |____host_vars
| | |____{{ SOMEHOST }}.yaml
| |____nodes
| | |____{{ SOME_NODE_GROUP }}
| | | |____{{ SOME_NODE }}.yaml
```

As illustrated above, node definitions are done via [YAML].

### Project Settings

All project-specific settings are also defined via YAML/ERB: [etc/vagrant.config.yaml](etc/vagrant.config.yaml)

### Ansible

The ansible provisionment objects reside under the **provisioners** directory:

```
|____ansible
| |____ansible.cfg
| |____examples
| |____inventory.py
| |____playbooks
| |____roles
| |____roles.global
```

Ansible task invocation occurs as specified in the corresponding node yaml definition file using references to [playbooks](playbook), [inline](inline) code, or a combination of both. Review the [Appendix](Appendix) for examples.

[YAML]: https://en.wikipedia.org/wiki/YAML
[ERB]: http://www.stuartellis.name/articles/erb/

[Overview]: #Overview

## Requirements

This repository utilizes the below software:

- [Ansible](https://www.ansible.com)
- Supported Hypervisors:
  - [libvirt/kvm](https://libvirt.org/drvqemu.html)
  - [VirtualBox](https://www.virtualbox.org)
- [Vagrant](https://www.vagrantup.com)
  - With the following Plugins:
    - [vagrant-reload](https://github.com/aidanns/vagrant-reload#installation)
    - [vagrant-hostsupdater](https://github.com/cogitatio/vagrant-hostsupdater)
    - [vagrant-group](https://github.com/vagrant-group/vagrant-group)
    - [vagrant-disksize](https://github.com/sprotheroe/vagrant-disksize)
    - [vagrant-libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt) (generally if you're on a linux Virtual Host, tested on CentOS Linux)
    - [vagrant-vbguest](https://github.com/dotless-de/vagrant-vbguest) (This is for virtualbox)
    - [vagrant-hosts](https://github.com/oscar-stack/vagrant-hosts)
    - [vagrant-managed-servers](https://github.com/tknerr/vagrant-managed-servers)


**Note:** You'll be warned of any missing plugins, so make sure to install these. Otherwise, you will likely encounter an error at some point during project execution.
Required plugins are defined in the config file: [etc/vagrant.config.yaml](etc/vagrant.config.yaml). You can modify these per your discretion of course.

**Lastly**, if you want to use [Puppet](https://puppet.com/) as your provisioner of choice, some code is in place to allow that, but this is not as well supported as ansible. Consult the [Appendix](#puppet) for more information.

[Requirements]: #Requirements

## Information

The sample environment consists of the following:

  -   1 [Docker](https://www.docker.com) node, type: virtual
  -   1 [CentOS](https://www.centos.org/) `7.x` node, type: virtual
  -   1 [Ubuntu](https://www.ubuntu.com) `16.04` node, type: virtual
  -   1 Managed, pre-existing physical host, type: baremetal
      - **Notes**: 
        - You must provide the host/ip for this machine
        - TODO: Get provisionment steps to work against managed nodes

## Getting started

**In this section** [Installing the tools] | [Creating your first workstation]  

**Note** This section assumes you are familiar with the basics of Vagrant. If that's not the case, it's recommended that you take a quick look at its [getting started guide][VagrantGettingStarted].  

**Note** The workstations defined herein have been tested on CentOS Linux (with kvm/libvirt), and on OSX and Windows (with Virtualbox). For issues, please submit via the standard Issue Tracking.

[Getting started]: #getting-started

[VagrantGettingStarted]: https://www.vagrantup.com/intro/getting-started/index.html

### Installing the tools

**In this section** [Install Using Bootstrap Script] | [Installing VirtualBox] | [Installing LibVirt] | [Installing Vagrant] | [Installing Docker]

If you're working from a Windows or Mac OSX platform, you'll most likely be working with Virtualbox. If you're on Linux, you can use either Virtualbox or KVM/Libvirt.

Follow the steps in the next sections to install the required tools, or skip all of that and do it automagically via the provided bootstrap script. See [Install Using Bootstrap Script]

#### Installing VirtualBox

1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads). 
  - At the time of writing, the VirtualBox version in use on the host was VirtualBox version 5.2.8 r121009.
  - If you want to specify a default provider, declare the environment variable `VAGRANT_DEFAULT_PROVIDER` with the value of `virtualbox` or `libvirt` to prevent specifying it every time a machine is booted.

[Installing VirtualBox]: #installing-virtualbox

#### Installing LibVirt

See the [Appendix](#libvirt) for instructions

[Installing LibVirt]: #installing-libvirt

#### Installing Vagrant

1. Install [Vagrant](https://www.vagrantup.com/docs/installation/)
1. Install the following plugins using `rake`[\*]() or `vagrant plugin install {{PLUGIN_NAME}}`:
    - [vagrant-reload](https://github.com/aidanns/vagrant-reload#installation)
    - [vagrant-hostsupdater](https://github.com/cogitatio/vagrant-hostsupdater)
    - [vagrant-group](https://github.com/vagrant-group/vagrant-group)
    - [vagrant-disksize](https://github.com/sprotheroe/vagrant-disksize)
    - [vagrant-libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt) (generally if you're on a linux Virtual Host, tested on CentOS Linux)
    - [vagrant-vbguest](https://github.com/dotless-de/vagrant-vbguest) (This is for virtualbox)
    - [vagrant-hosts](https://github.com/oscar-stack/vagrant-hosts)
    - [vagrant-managed-servers](https://github.com/tknerr/vagrant-managed-servers)
1. Install any additional tools for the virtualization provider of your choosing
    
**Again**, you'll be warned of any missing plugins when calling `vagrant` commands. You can manage which plugins are required by modifying [etc/vagrant.config.yaml](etc/vagrant.config.yaml)

**Note:** The author of the [vagrant-group](https://github.com/vagrant-group/vagrant-group), plugin hasn't made updates to the code in over a few years. Because I wanted additional features, I forked the git repo and modified the plugin. You can use my forked version if you wish. See the [Appendix](#plugins) for more information.

Some Vagrant documentation for review:
- [VagrantEnvDefaultProvider](https://www.vagrantup.com/docs/other/environmental-variables.html#vagrant_default_provider)
- [VagrantCliUpProvider](https://www.vagrantup.com/docs/cli/up.html#provider-x)

[Installing Vagrant]: #installing-vagrant

#### Installing Docker

For installing [Docker](https://www.docker.com/), see the [Appendix](#docker)

[Installing Docker]: #installing-docker

[Installing the tools]: #installing-the-tools

### Creating your first workstation

<!--
TODO: samples: add output of Vagrant
-->

**Note** Booting a workstation for the first time can be a lengthy process. If you have a slow internet connection, downloading any given [vagrant box](https://www.vagrantup.com/docs/boxes.html) - usually several GBs for some OS types - may take up to an hour or more. Creating another machine from the same box later, however, will reuse the already downloaded virtual disk image, thus drastically reducing the startup time. For troubleshooting tips, consult the [Appendix](#troubleshooting)  

**Note** The examples in this section allow for creation of virtual nodes with a default set of sample configurations, focusing on demonstrating the management of the defined machines in general. Consult the [Appendix](Appendix) for instructions on how to customize these according to your preferences.

You are now ready to create your workstations with Vagrant.

Again, clone this repository and navigate to the root directory of the workspace using your shell. Then, issue the `vagrant status` command to list available machines:

```sh
git$ git clone https://github.com/berttejeda/vagrant-venv.git
git$ cd vagrant-environments
git/vagrant-environments$ vagrant status
```

The output will be something similar to this:

```
web01.contoso.com                      not_created (virtualbox)
```

The list shows the four default workstations, `web01.contoso.com` intended to support the microservices projects you work on, `web01` for generic experiments with CentOS Linux, `ubuntu01` for experiments with Ubuntu Linux, and `physical01.contoso.com` to showcase interaction with a **physical**, that is **REAL** host. None of these are `created`, as you can see, and in the case of the `managed` node, [reachable][reachable]

Let's bring up the `web01.contoso.com` Node
```sh
git/vagrant-environments$ vagrant up web01.contoso.com
```

Now we must wait. The box - in this case `ubuntu/xenial64` - will be downloaded from [hashicorp vagrant cloud](https://app.vagrantup.com/boxes/search) and the machine will be provisioned according to its [node definition]((environments/contoso/nodes/web-servers/web01.contoso.com.yaml)). Again, if you encounter problems in downloading the box, consult the [Appendix](troubleshooting).

If you've already booted up a machine, but realize that it's not using the configuration you want, you can always terminate the process with `ctrl + c`. Depending on how far vagrant gets with the virtual machine creation, you may have to destroy the machine afterwards, with `vagrant destroy {{ MACHINE_NAME }}`

Once the machine is ready, you can connect to it via `ssh` with `vagrant ssh {{ MACHINE_NAME }}`

```sh
git/vagrant-environments$ vagrant ssh web01.contoso.com
``` 

To exit the virtual machine, press `ctrl + d` or enter `exit` while at the terminal.

Again, you can check the status of all defined machines with the `vagrant status` command. To review the state of any single machine, enter `vagrant status {{MACHINE_NAME}}`. This **must** be done from the project root[\*](the-environments)

```sh
vagrant status
docker01                                   not_created (virtualbox)
web01.contoso.com                          running (virtualbox)
ubuntu01                                   not_created (virtualbox)
physical01.contoso.com                     not_created (managed)
```

```sh
vagrant status web01.contoso.com
web01.contoso.com                          running (virtualbox)
```

When you've finished with your work, you can shut down the machine with `vagrant halt {{MACHINE_NAME}}`. This will preserve the machine's state, so the next time you invoke `vagrant up`, boot time will be significantly faster, and any files you may have created on the node will persist.

```sh
git/vagrant-environments$ vagrant halt web01.contoso.com
```

**Pro-tip**: The `vagrant global-status` command will list all machines on your host, regardless of your location.

```sh
$ vagrant global-status
id       name     provider   state    directory
----------------------------------------------------------------------------------------------------------
8901234  web01.contoso.com virtualbox poweroff C:/Users/tomtester/git/vagrant-environments
```

If you no longer need a machine, you can destroy it. As expected, this will wipe it completely from your system, and on the next `vagrant up`, it will be provisioned again from scratch:

```sh
git/vagrant-environments$ vagrant destroy web01.contoso.com
```
The box will remain on your system after destroying the machine, as verified by `vagrant box list`. You can use `vagrant box remove` to clean up unwanted boxes.

[Creating your first workstation]: #creating-your-first-workstation

## Contributing

**Note** At this point you might want to fork this repository and create your own branch to save your changes and to compare your customizations easily with others.

[How To Fork This Repo](https://confluence.atlassian.com/bitbucket/forking-a-repository-221449527.html)
[How To Compare Your Work](https://confluence.atlassian.com/bitbucketserverkb/understanding-diff-view-in-bitbucket-server-859450562.html)

[Contributing]: #contributing

## Appendix

<!--
TODO: download optimization and / or build own
TODO: vagrant options
TODO: vagrant extensions (e.g. ruby block)
-->

[Appendix]: #appendix

**In this section** [Usage Examples] | [Using Inline Ansible Tasks] | [Specifying Ansible Playbooks] | [Using A Combination Of Both]

## Usage Examples

### Node Definitions

#### Using Inline Ansible Playbooks

* You want to define a node such that:
  - OS is Centos 7
  - Memory: 512MB
  - Video Options: None
  - Virtual CPUs: 1
  - Upon machine provisionment, ansible will:
    - Install any system updates
    - Install python, git

Solution:

Let your node definition file be `environments/contoso/nodes/centos-workstations/centos02.yaml`

You can accomplish this with the following node `yaml`:

[Usage Examples]: #usage-examples

[inline]: #inline

```yaml
---
- name: 'centos02'
  groups:
    - 'centos'
  box: 'centos/7'
  desktop: false
  mem: 512
  provision: true
  vcpu: 1
  provisioners:
    - ansible:
        inventory: "environments/contoso/hosts"
        gather_facts: true
        become: True        
        tasks:
          - name: Install system updates
            yum: name=* state=latest update_cache=yes
            ignore_errors: true
          - name: Install packages 
            yum: 
              name: "{{ item }}"
              state: present
            with_items:
              - python-devel
              - '@C Development Tools and Libraries'
              - git
```

As you can see from the above example, we've defined the ansible tasks inline, so there's no need for a separate playbook file to be referenced. 

Once you've created the node definition, verify that vagrant is aware of the newly defined machine:

```sh
vagrant status
```

Bring up the machine and observe how it goes from the initial bootup phase to the ansible bootstrap step, and finally into the provisionment steps, wherein the ansible tasks take action:

```sh
vagrant up centos02
```

#### Specifying Ansible Playbooks

The same can be accomplished by offloading the tasks to a separate playbook file and referencing this in the node YAML, as with:

[playbook]: #playbook

```yaml
---
- name: 'centos02'
  groups:
    - 'centos'
  box: 'centos/7'
  desktop: false
  mem: 512
  provision: true
  vcpu: 1
  provisioners:
    - ansible:
        inventory: "environments/contoso/hosts"
        playbooks: 
          - include: bootstrap.yaml
```

Where [bootstrap.yaml](provisioners/ansible/playbooks/bootstrap.yaml) contains the previously inlined ansible tasks.

#### Using A Combination Of Both

If you have a need to combine a call to a playbook with inline tasks, this can also be done. Simply include the reference to the playbook along with the line code, as with:

[combination]: #combination

```yaml
---
- name: 'centos02'
  groups:
    - 'centos'
  box: 'centos/7'
  desktop: false
  mem: 512
  provision: true
  vcpu: 1
  provisioners:
    - ansible:
        inventory: "environments/contoso/hosts"
        gather_facts: true
        become: True
        playbooks: 
          - include: bootstrap.yaml      
        tasks:
          - name: Install some one-off packages 
            yum: 
              name: "{{ item }}"
              state: present
            with_items:
              - screen
              - bind-utils
```

If you don't specify a fully qualified path to the playbook file, the parent folder for the given playbook will default to `provisioners/ansible/playbooks`, and in the case of working from Windows, `/vagrant/provisioners/ansible/playbooks`.

If you'd like to call multiple playbooks, you can simply list them as an array conforming to `include: {{PLAYBOOK}}`[\*](include_keyword), as with:

```yaml
---
- name: 'centos02'
  groups:
    - 'centos'
  box: 'centos/7'
  desktop: false
  mem: 512
  provision: true
  vcpu: 1
  provisioners:
    - ansible:
        inventory: "environments/contoso/hosts"
        gather_facts: true
        become: True
        playbooks: 
          - include: bootstrap.yaml
          - include: centos02.yaml      
        tasks:
          - name: Install some one-off packages 
            yum: 
              name: "{{ item }}"
              state: present
            with_items:
              - screen
              - bind-utils
```

Where [bootstrap.yaml](provisioners/ansible/playbooks/bootstrap.yaml) and [centos02.yaml](provisioners/ansible/playbooks/centos02.yaml) contain their own set of ansible configurations.

Again, if you don't specify a fully qualified path to the playbook file, the parent folder will be implied as stated before.

A note on the `include` statement:

It is due to be removed from Ansible version 2.8 on. If you're working with Ansible 2.5+, you'll likely see a Deprecation warning when using this statement. It's recommended you use `import_playbook` instead. Another caveat: By default, the project settings for dynamic playbooks (as defined inline to node definition) utilizes this very same `include` statement. To change that, simply modify the `default_include_statement` settings key accordingly  in [vagrant.config.yaml](etc/vagrant.config.yaml).

## Puppet

TODO: ADD Documentation for Puppet Provisionment

## Libvirt

TODO: ADD Documentation for Installing and using Libvirt

## Extras

### Custom Commands

Custom vagrant commands are defined via the .vagrantplugins mechanism.

This is not officially supported by Hashicorp, but it remains a means to define ad-hoc plugins. I have leveraged this feature to abstract the definition of custom commands via a handy yaml file. Have a looksee: 

- [.vagrantplugins](.vagrantplugins)
- [commands.extra.yaml](etc/commands.extra.yaml)

### Plugins

TODO: ADD Documentation for Installing my custom `vagrant-group` plugin

## Docker

TODO: ADD Documentation for Installing and leveraging `docker-machine` with the project

## Troubleshooting

[include_keyword]: #include_keyword

TODO: ADD Documentation for troubleshooting scenarios