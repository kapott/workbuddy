# workbuddy

Ansible scripts to push different kinds of work environments to remote linux boxes.
Assume every application is a role. Every role combines into a playbook which is aimed at performing some function.

### Tool examples
Install all tools locally (dotfiles, plugins etc.)
`ansible-playbook local-tools.yml -i ./inventories/localhost --ask-become-pass`

Install only certain tools. (Vim and tmux in this example.)
`ansible-playbook local-tools.yml -i ./inventories/localhost --tags vim,tmux --ask-become-pass`

### Desktop examples

Install i3wm with gaps, rofi etc.
`ansible-playbook local-i3wm.yml -i ./inventories/localhost --ask-become-pass`


### Arch, freebsd, fedora copr

Install the ansible-galaxy community collection:
`ansible-galaxy collection install community.general`


### Todo list

- [ ] 
- [ ] i3wm workspace assignment for most used apps
- [ ] use and configure polybar
- [ ] sub rxvt with alacritty
- [ ] find or makedecent colorscheme to make everything coherent (vim,tmux,i3,rofi)
- [ ] find or make decent networking script / indicator for the statusbar
- [ ] find or make decent sound device and volume control for statusbar
- [ ] find or make a decent battery indicator for i3

### Reference material

[Ansible best practises](https://docs.ansible.com/ansible/2.8/user_guide/playbooks_best_practices.html)
