# Hardware configuration for Lenovo Legion 16ACH6H
# Generate this file with: nixos-generate-config --show-hardware-config
# This is a template - replace with actual hardware scan output

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Kernel modules
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # Filesystem mounts (ADJUST THESE TO YOUR ACTUAL DISK LAYOUT)
  # Run `lsblk` to see your actual devices and UUIDs

  # Root partition
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-YOUR-ROOT-UUID";
    fsType = "ext4";
  };

  # EFI System Partition
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-YOUR-BOOT-UUID";
    fsType = "vfat";
  };

  # Swap (optional, adjust or remove as needed)
  swapDevices = [
    # { device = "/dev/disk/by-uuid/REPLACE-WITH-YOUR-SWAP-UUID"; }
  ];

  # High-DPI console font for Legion's display
  console.font = "ter-i32b";
  console.packages = [ pkgs.terminus_font ];

  # Hardware-specific settings
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.enableRedistributableFirmware = lib.mkDefault true;
}
