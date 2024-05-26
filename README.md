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

- [x] Add i3wm debian role
- [x] i3wm workspace assignment for most used apps
- [x] sub rxvt with alacritty
- [ ] Find or makedecent colorscheme to make everything coherent (vim,tmux,i3,rofi)
- [ ] Add IOSevka nerdfonts to the i3 installation
- [ ] Theme Rofi
- [ ] Theme Polybar
- [ ] Add wallpapers role
- [ ] Add ThePrimagen's tmux workflow into environment
- [ ] Add Neovim migration role for when I work locally

### Reference material

[Ansible best practises](https://docs.ansible.com/ansible/2.8/user_guide/playbooks_best_practices.html)
