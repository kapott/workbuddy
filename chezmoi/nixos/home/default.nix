{ config, pkgs, ... }:

{
  # Home Manager configuration for user therder

  home.username = "therder";
  home.homeDirectory = "/home/therder";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # User packages
  home.packages = with pkgs; [
    # CLI tools
    bat
    eza
    fd
    jq
    yq
    tree
    ncdu

    # Development
    nodejs_20
    python3

    # DevOps tools
    kubectl
    helm
    terraform
    ansible

    # Cloud CLIs
    awscli2

    # Containers
    podman

    # Misc
    neofetch
    starship
  ];

  # ZSH configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "refined";
      plugins = [
        "git"
        "z"
        "fzf"
        "kubectl"
        "helm"
        "docker"
        "terraform"
        "aws"
      ];
    };

    initExtra = ''
      # Source shared bash functions
      if [ -d ~/.bashrc.d ]; then
        for rc in ~/.bashrc.d/10-aliases ~/.bashrc.d/20-functions ~/.bashrc.d/21-update; do
          [ -e "$rc" ] && . "$rc"
        done
      fi

      # Starship prompt
      eval "$(starship init zsh)"
    '';

    shellAliases = {
      ls = "eza";
      ll = "eza -la";
      cat = "bat";
    };
  };

  # Git configuration
  programs.git = {
    enable = true;
    userName = "kapott";
    userEmail = "kapott@aivd.33mail.com";

    extraConfig = {
      push.default = "simple";
      pull.rebase = false;
      core.editor = "vim";
      color.ui = true;
    };

    aliases = {
      a = "add";
      b = "branch";
      c = "commit";
      d = "diff";
      st = "status";
      co = "checkout";
    };
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "";
        error_symbol = "";
      };
      directory = {
        truncation_length = 1;
        truncation_symbol = ".../";
        home_symbol = " ~";
      };
      git_branch = {
        symbol = " ";
        style = "bold green";
      };
      kubernetes = {
        disabled = false;
        format = "via [k8s $context($namespace)](bold purple) ";
      };
    };
  };

  # FZF
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "rg --files --hidden";
  };

  # Kitty terminal
  programs.kitty = {
    enable = true;
    font = {
      name = "Hack Nerd Font Mono";
      size = 16;
    };
    settings = {
      window_padding_width = 8;
      scrollback_lines = 10000;
      enable_audio_bell = false;
      cursor_shape = "block";
      cursor_blink_interval = 0;
      copy_on_select = "clipboard";
      # Monokai Pro colors
      foreground = "#fff1f3";
      background = "#2c2525";
      color0 = "#2c2525";
      color8 = "#72696a";
      color1 = "#fd6883";
      color9 = "#fd6883";
      color2 = "#adda78";
      color10 = "#adda78";
      color3 = "#f9cc6c";
      color11 = "#f9cc6c";
      color4 = "#f38d70";
      color12 = "#f38d70";
      color5 = "#a8a9eb";
      color13 = "#a8a9eb";
      color6 = "#85dacc";
      color14 = "#85dacc";
      color7 = "#fff1f3";
      color15 = "#fff1f3";
    };
  };

  # Tmux
  programs.tmux = {
    enable = true;
    prefix = "C-Space";
    mouse = true;
    keyMode = "vi";
    baseIndex = 1;
    escapeTime = 1;
    historyLimit = 10000;

    extraConfig = ''
      # Split panes using | and -
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Vim-style pane selection
      bind -n C-h select-pane -L
      bind -n C-j select-pane -D
      bind -n C-k select-pane -U
      bind -n C-l select-pane -R
    '';
  };

  # Vim
  programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      gruvbox
      vim-tmux-navigator
      fzf-vim
      vim-gitgutter
      vim-fugitive
    ];
    extraConfig = builtins.readFile ../../../dot_vimrc;
  };

  # XDG directories
  xdg.enable = true;

  # This value determines the Home Manager release
  home.stateVersion = "24.05";
}
