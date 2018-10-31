Creating your first workstation


<!--
TODO: samples: add output of Vagrant
-->

**Note** Booting a workstation for the first time can be a lengthy process. If you have a slow internet connection, downloading any given [vagrant box](https://www.vagrantup.com/docs/boxes.html) - usually several GBs for some OS types - may take up to an hour or more. Creating another machine from the same box later, however, will reuse the already downloaded virtual disk image, thus drastically reducing the startup time. For troubleshooting tips, consult the [Appendix](#troubleshooting)  

**Note** The examples in this section allow for creation of virtual nodes with a default set of sample configurations, focusing on demonstrating the management of the defined machines in general. Consult the [Appendix](Appendix) for instructions on how to customize these according to your preferences.

You are now ready to create your workstations with Vagrant.

Again, clone this repository and navigate to the root directory of the workspace using your shell. Then, issue the `vagrant status` command to list available machines:

```sh
git$ git clone https://git.ufn.from-pa.com:8443/etejeda/vagrant-venv.git
git$ cd vagrant-venv
git/vagrant-venv$ vagrant status
```

The output will be something similar to this:

```
docker01                      not_created (virtualbox)
centos01                      not_created (virtualbox)
ubuntu01                      not_created (virtualbox)
managed01                     not_created (managed)
```

The list shows the four default workstations, `docker01` intended to support the microservices projects you work on, `centos01` for generic experiments with CentOS Linux, `ubuntu01` for experiments with Ubuntu Linux, and `managed01` to showcase interaction with a **physical**, that is **REAL** host. None of these are `created`, as you can see, and in the case of the `managed` node, [linked][linked]

Let's bring up the `Centos` Node
```sh
git/vagrant-venv$ vagrant up centos01
```

Now we must wait. The box - in this case `centos/7` - will be downloaded from [hashicorp vagrant cloud](https://app.vagrantup.com/boxes/search) and the machine will be provisioned according to its [node definition]((environments/allentown/nodes/linux-workstations/centos01.yaml)). Again, if you encounter problems in downloading the box, consult the [Appendix](troubleshooting).

If you've already booted up a machine, but realize that it's not using the configuration you want, you can always terminate the process with `ctrl + c`. Depending on how far vagrant gets with the virtual machine creation, you may have to destroy the machine afterwards, with `vagrant destroy {{ MACHINE_NAME }}`

Once the machine is ready, you can connect to it via `ssh` with `vagrant ssh {{ MACHINE_NAME }}`

```sh
git/vagrant-venv$ vagrant ssh centos01
``` 

To exit the virtual machine, press `ctrl + d` or enter `exit` while at the terminal.

Again, you can check the status of all defined machines with the `vagrant status` command. To review the state of any single machine, enter `vagrant status {{MACHINE_NAME}}`. This **must** be done from the project root[\*](the-environments)

```sh
vagrant status
docker01                      not_created (virtualbox)
centos01                      running (virtualbox)
ubuntu01                      not_created (virtualbox)
managed01                     not_created (managed)
```

```sh
vagrant status centos01
centos01                      running (virtualbox)
```

When you've finished with your work, you can shut down the machine with `vagrant halt {{MACHINE_NAME}}`. This will preserve the machine's state, so the next time you invoke `vagrant up`, boot time will be significantly faster, and any files you may have created on the node will persist.

```sh
git/vagrant-venv$ vagrant halt centos01
```

**Pro-tip**: The `vagrant global-status` command will list all machines on your host, regardless of your location.

```sh
$ vagrant global-status
id       name     provider   state    directory
----------------------------------------------------------------------------------------------------------
8901234  centos01 virtualbox poweroff C:/Users/tomtester/git/vagrant-venv
```

If you no longer need a machine, you can destroy it. As expected, this will wipe it completely from your system, and on the next `vagrant up`, it will be provisioned again from scratch:

```sh
git/vagrant-venv$ vagrant destroy centos01
```
The box will remain on your system after destroying the machine, as verified by `vagrant box list`. You can use `vagrant box remove` to clean up unwanted boxes.

More Usage Examples
-----------------

Node Definitions
-----------------

##### Using Inline Ansible Playbooks

* You want to define a node such that:
  - OS is Centos 7
  - Memory: 512MB
  - Video Options: None
  - Virtual CPUs: 1
  - Upon machine provisionment, ansible will:
    - Install any system updates
    - Install python, git

Solution:

Let your node definition file be `environments/allentown/nodes/centos-workstations/centos02.yaml`

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
        inventory: "environments/allentown/hosts"
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

##### Specifying Ansible Playbooks

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
        inventory: "environments/allentown/hosts"
        playbooks: 
          - include: bootstrap.yaml
```

Where [bootstrap.yaml](provisioners/ansible/playbooks/bootstrap.yaml) contains the previously inlined ansible tasks.

##### Using A Combination Of Both

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
        inventory: "environments/allentown/hosts"
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
        inventory: "environments/allentown/hosts"
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
