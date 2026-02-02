{ config, pkgs, ... }:

{
  # Enable Sway (Wayland compositor)
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swaylock
      swayidle
      swaybg
      waybar
      wofi
      mako
      grim
      slurp
      wl-clipboard
      wlr-randr
    ];
  };

  # Keyboard layout for Sway
  services.xserver.xkb = {
    layout = "us";
    variant = "";
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

    # Notifications
    libnotify

    # File manager
    pcmanfm
    xfce.thunar

    # Image viewer
    imv

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
    lxappearance  # GTK theme settings
    brightnessctl

    # Network
    networkmanagerapplet
  ];

  # Enable GVFS for file manager functionality
  services.gvfs.enable = true;

  # Thumbnail support
  services.tumbler.enable = true;

  # Dconf for GTK apps
  programs.dconf.enable = true;

  # XDG portal for Wayland screen sharing etc.
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Environment variables for Wayland
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    XDG_CURRENT_DESKTOP = "sway";
    XDG_SESSION_TYPE = "wayland";
  };

  # Polkit for authentication dialogs
  security.polkit.enable = true;

  # GREETD display manager for Wayland
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd sway";
        user = "greeter";
      };
    };
  };
}
