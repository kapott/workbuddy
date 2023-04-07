# workbuddy
Ansible scripts to push different kinds of work environments to remote linux boxes.
Assume every application is a role. Every role combines into a playbook which is
aimed at performing some function.

`ansible-playbook tools.yml -i ./inventories/production -e minimal=false -t=vim,bash,tmux`

[Ansible best practises](https://docs.ansible.com/ansible/2.8/user_guide/playbooks_best_practices.html)
