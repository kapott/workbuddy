{ config, lib, pkgs, ... }:

{
  # NVIDIA driver configuration for hybrid graphics
  # Legion 16ACH6H has AMD Ryzen 5800H (with AMD iGPU) + NVIDIA RTX 3060/3070

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Load NVIDIA driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Modesetting is required for most Wayland compositors
    modesetting.enable = true;

    # Use the open source kernel module (for newer GPUs)
    # Set to false if you have issues
    open = false;

    # Enable the NVIDIA settings menu
    nvidiaSettings = true;

    # Use the production driver (stable)
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # PRIME configuration for hybrid graphics
    prime = {
      # Offload mode: AMD iGPU as primary, NVIDIA dGPU on-demand
      offload = {
        enable = true;
        enableOffloadCmd = true;  # Provides nvidia-offload command
      };

      # Bus IDs - find yours with: lspci | grep -E 'VGA|3D'
      # Format is: "PCI:bus:device:function"
      amdgpuBusId = "PCI:6:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };

    # Power management (experimental)
    powerManagement = {
      enable = true;
      # Fine-grained power management (turns off GPU when not in use)
      # Requires NVIDIA driver 510.39.01 or higher
      finegrained = true;
    };
  };

  # Environment variables for NVIDIA
  environment.sessionVariables = {
    # For Electron apps on Wayland
    NIXOS_OZONE_WL = "1";
  };

  # Useful packages for GPU management
  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia  # GPU monitoring
    glxinfo               # OpenGL info
    vulkan-tools          # Vulkan info
  ];
}
