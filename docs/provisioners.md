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

Ansible task invocation occurs as specified in the corresponding machine definition file (.yaml) using references to [playbooks](playbook), [inline](inline) code, or a combination of both. 

Review the [Appendix](Appendix) for examples.

[YAML]: https://en.wikipedia.org/wiki/YAML
[ERB]: http://www.stuartellis.name/articles/erb/
