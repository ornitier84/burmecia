import vagrant
from fabric.api import *

@task
def start(machine_name):
   """Starts the specified machine using vagrant"""
   v = vagrant.Vagrant()
   v.up(vm_name=machine_name)
   with settings(host_string= v.user_hostname_port(vm_name=machine_name),
                 key_filename = v.keyfile(vm_name=machine_name),
                 disable_known_hosts = True):
        run("hostname")