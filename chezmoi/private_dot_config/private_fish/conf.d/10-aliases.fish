# Aliases, kept in step with ~/.bashrc.d/10-aliases so the three shells agree.
#
# Two families from the CachyOS config are deliberately left out: the joke
# aliases that map apt and apt-get onto `man pacman`, because they shadow the
# real thing inside a Debian container, and `wget='wget -c'`, because silently
# changing wget's resume behaviour bites exactly once and takes an hour to find.

# Recolour remaps
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias tmux='tmux -u'

# Listing. eza when present, ls otherwise, same letters either way.
if type -q eza
    alias ls='eza -a --color=always --group-directories-first --icons=always'
    alias ll='eza -l --color=always --group-directories-first --icons=always'
    alias la='eza -al --color=always --group-directories-first --icons=always'
    alias lt='eza -aT --color=always --group-directories-first --icons=always'
    alias l.="eza -a | grep -e '^\.'"
else
    alias ls='ls --color=auto'
    alias ll='ls -ahlF --group-directories-first'
    alias la='ls -A'
    alias lt='ls --human-readable --size -1 -S --classify'
end

# One letter
alias f='find'
alias g='git'
alias t='tmux new -AsBOFH'
alias k='kubectl'
alias l='ls'
alias v='vim'
alias u='upg'

# Two letter
alias ff='find . -type f -name'
alias gh='history | grep'
alias sv='sudo vim'

# Walking up
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# systemd
alias s='systemctl'
alias scat='systemctl cat'
alias sstat='systemctl status'
alias srl='systemctl reload'
alias sstop='systemctl stop'
alias sstart='systemctl start'
alias stimers='systemctl list-timers --all'
alias aan='sstart'
alias uit='sstop'
alias log='journalctl -eu'
alias logf='journalctl -efu'
alias jctl='journalctl -p 3 -xb'

# Certificates
alias crt_expiration='openssl x509 -enddate -noout -in'
alias crt_info='openssl x509 -noout -text -in'
alias crt_modulus='openssl x509 -noout -modulus -in'
alias key_modulus='openssl rsa -noout -modulus -in'
alias csr_modulus='openssl req -noout -modulus -in'

# Processes by memory
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'

# Arch-family housekeeping, the part of the CachyOS config worth keeping.
if type -q pacman
    alias fixpacman='sudo rm /var/lib/pacman/db.lck'
    alias cleanup='sudo pacman -Rns (pacman -Qtdq)'
    alias gitpkg='pacman -Q | grep -i "\-git" | wc -l'
    type -q expac; and alias big="expac -H M '%m\t%n' | sort -h | nl"
    type -q expac; and alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"
    type -q cachyos-rate-mirrors; and alias mirror='sudo cachyos-rate-mirrors'
end
type -q hwinfo; and alias hw='hwinfo --short'
