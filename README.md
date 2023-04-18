# workbuddy

Ansible scripts to push different kinds of work environments to remote linux boxes.
Assume every application is a role. Every role combines into a playbook which is aimed at performing some function.

Install all tools locally (dotfiles, plugins etc.)
`ansible-playbook local-tools.yml -i ./inventories/localhost --ask-become-pass`

Install only certain tools. (Vim and tmux in this example.)
`ansible-playbook local-tools.yml -i ./inventories/localhost --tags vim,tmux --ask-become-pass`



[Ansible best practises](https://docs.ansible.com/ansible/2.8/user_guide/playbooks_best_practices.html)
