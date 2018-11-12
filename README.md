Introduction
-----------------

What is vagrant-venv?

- Mult-Machine Environment using Vagrant
- Multi-tenancy (environments/*)
- Virtual Machines defined via yaml
- Many vagrant options abstracted via yaml
- Ansible for provisioning (supports puppet manifests as well)

In a nutshell, what you've got here is a portable virtual infrastructure 
leveraging vagrant for machine deployments and ansible/puppet for machine provisionment.

Quick start
-----------------

Once you've `installed
<https://www.vagrantup.com/docs/installation/>`__ vagrant, start
by activating the sample environment:

.. code-block:: console

    $ vagrant environment activate contoso
    Activating vagrant environment contoso
    Environment context file is .vagrant/tmp/.environment_context.

create your environment inventory file:

.. code-block:: console

    $ vagrant inventory create contoso
    Writing inventory file environments/contoso/inventory.yaml
    Done!    

Next, review your machine states:

.. code-block:: console

    $ vagrant status
    Current machine states:

    ansible.contoso.com       not created (virtualbox)
    web01.contoso.com         not created (virtualbox)    

Start the your virtual machines:

.. code-block:: console

    $ vagrant up
    Bringing machine 'ansible.contoso.com' up with 'virtualbox' provider...
    Bringing machine 'web01.contoso.com' up with 'virtualbox' provider...

- SSH into a virtual machine
  - `vagrant ssh {{ MACHINE_NAME }}`
- Power Off a virtual machine
  - `vagrant halt {{ MACHINE_NAME }}`
- Apply provisionment steps (ansible) against virtual machine
  - `vagrant provision {{ MACHINE_NAME }}`

You can `ssh` to any of the machines with `vagrant ssh {{ MACHINE_NAME }}` 
e.g. `vagrant ssh ansible.contoso.com`

To apply provisionment steps to a machine, simply run `vagrant provision {{ MACHINE_NAME }} {{ ANSIBLE_CONTROLLER_NAME }}`, e.g.
`vagrant provision web01.contoso.com ansible.contoso.com`

**Note:** The above is necessary when the _ansible_ operational mode is set to 'controller', which is the project default.

For more detailed information on provisioner logic, consult [docs/provisioners.md](docs/provisioners.md)

For more usage examples, read [docs/usage.md](docs/usage.md)

The following sections cover the project details at greater length.

The Environments
-----------------

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
| | | |____ubuntu01.yaml
| | | |____ubuntu02.yaml
| | |____inventory.yaml
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

Machine Definitions
-----------------

A machine definition consists of yaml-formatted text file with at minimum the following structure:

.. code-block:: yaml
- name: '<%= @machine_name %>'
  config:
    box: '<%= @machine_box %>'
    hostname: '<%= @machine_name %>'
  provider:
    virtualbox:
      modifyvm:
        name: '<%= @machine_name %>'
        memory: 512
        cpus: 1

Notice the dynamic values: ``'<%= @machine_name %>'``; these are placeholders that evaluate to the result computed between the `<%= %>`, which is the base name of the yaml file.

In this case, the machine name reflects the file name of its machine definition file.

You can, of course, hardcode the machine name in its definition file if you like.

For a full list of supported keys, consult [docs/machines.md](docs/machines.md)

Provisioners
-----------------

The project supports the following vagrant provisioners:

- ansible
- puppet
- shell

For more detailed information on provisioner logic, consult [docs/provisioners.md](docs/provisioners.md)

Appendix
-----------------


Project Settings
-------

All project-specific settings are also defined via YAML/ERB: [etc/config.yaml](etc/config.yaml)

Softwares
-------

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

Troubleshooting
-------

Error_similar_to: `found unknown escape character while parsing a quoted scalar at line {{ someline }} column {{ somecolumn }}`
Possible_cause: **You set your VAGRANT_DOTFILE_PATH environment variable as .vagrant\myenvironment which causes a failure in parsing the yaml config file**
Possible_solution: **Escape the backslash in your path as follows: set VAGRANT_DOTFILE_PATH=.vagrant\\myenvironment**

License
-------

``vagrant-venv`` is licensed under `MIT License <https://opensource.org/licenses/MIT>`__. You can find the
complete text in ``LICENSE``.
