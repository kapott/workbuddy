{ config, pkgs, ... }:

{
  # X11 and Display Manager
  services.xserver = {
    enable = true;

    # Display manager
    displayManager.lightdm.enable = true;

    # i3 window manager
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        i3status
        i3lock
        dmenu
        rofi
      ];
    };

    # Keyboard layout
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Enable touchpad support
  services.libinput.enable = true;

  # Fonts
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      # Nerd Fonts
      (nerdfonts.override { fonts = [ "Hack" "FiraCode" "JetBrainsMono" ]; })

      # Other useful fonts
      liberation_ttf
      dejavu_fonts
      noto-fonts
      noto-fonts-emoji
    ];

    fontconfig = {
      defaultFonts = {
        monospace = [ "Hack Nerd Font Mono" ];
        sansSerif = [ "DejaVu Sans" ];
        serif = [ "DejaVu Serif" ];
      };
    };
  };

  # Desktop applications
  environment.systemPackages = with pkgs; [
    # Terminal emulator
    kitty

    # Status bar
    polybar

    # Application launcher
    rofi

    # Notifications
    dunst
    libnotify

    # Compositor
    picom

    # Wallpaper
    feh
    nitrogen

    # Screenshot
    flameshot
    scrot

    # File manager
    pcmanfm
    xfce.thunar

    # Image viewer
    feh
    sxiv

    # PDF viewer
    zathura

    # Browsers
    firefox

    # Communication
    signal-desktop

    # Media
    mpv
    pavucontrol

    # Utilities
    xclip
    xsel
    arandr  # Display configuration
    lxappearance  # GTK theme settings

    # Network
    networkmanagerapplet
  ];

  # Enable GVFS for file manager functionality
  services.gvfs.enable = true;

  # Thumbnail support
  services.tumbler.enable = true;

  # Screen locker
  programs.xss-lock = {
    enable = true;
    lockerCommand = "${pkgs.i3lock}/bin/i3lock -c 000000";
  };

  # Dconf for GTK apps
  programs.dconf.enable = true;

  # XDG portal for screen sharing etc.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
