# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').
{ config, pkgs, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # --- tpm2 stuffy
  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices."luks-8d4fec51-dfcc-4c14-87bb-baf473ba01f4" = {
    device = "/dev/disk/by-uuid/8d4fec51-dfcc-4c14-87bb-baf473ba01f4";
    crypttabExtraOpts = [ "tpm2-device=auto" ];
  };
  # enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  networking.hostName = "solidus";
  # Enable networking
  networking.networkmanager.enable = true;
  # Set your time zone.
  time.timeZone = "Europe/London";
  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };
  # Enable the X11 windowing system.
  services.xserver.enable = true;
  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "gb";
    variant = "";
  };
  # Configure console keymap
  console.keyMap = "uk";
  # Enable CUPS to print documents.
  services.printing.enable = true;
  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users."fionn" = {
    isNormalUser = true;
    description = "fionn";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  # bash aliases
  programs.bash = {
    enable = true;
    shellAliases = {
      update = "sudo nix-channel --update && sudonixos-rebuild switch --flake /run/media/fionn/Storage/bigwhoop-nix/";
      update-dry = "sudo nixos-rebuild dry-build --flake /run/media/fionn/Storage/bigwhoop-nix/";
      update-boot = "sudo nix-channel --update && sudonixos-rebuild boot --flake /run/media/fionn/Storage/bigwhoop-nix/";
      upgrade = "sudo nix flake update --flake /run/media/fionn/Storage/bigwhoop-nix/ && sudo nixos-rebuild switch --flake /run/media/fionn/Storage/bigwhoop-nix/#";
    };
  };

  # Mount drives
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id.indexOf("org.freedesktop.udisks2") === 0 && subject.local && subject.active) {
        return polkit.Result.YES;
      }
    });
  '';
  systemd.user.services.automount-drives = {
    description = "Auto mount drives via udisksctl";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "mount-drives" ''
        ${pkgs.udisks2}/bin/udisksctl unmount --block-device /dev/disk/by-uuid/7aeb75d7-8b66-433c-a642-693c43d2726a --no-user-interaction || true
        ${pkgs.udisks2}/bin/udisksctl unmount --block-device /dev/disk/by-uuid/c99b8592-cb3c-43e4-9859-7fe6f323655b --no-user-interaction || true
        sleep 1
        ${pkgs.udisks2}/bin/udisksctl mount --block-device /dev/disk/by-uuid/7aeb75d7-8b66-433c-a642-693c43d2726a --no-user-interaction || true
        ${pkgs.udisks2}/bin/udisksctl mount --block-device /dev/disk/by-uuid/c99b8592-cb3c-43e4-9859-7fe6f323655b --no-user-interaction || true
      '';
    };
  };
  # Install firefox.
  programs.firefox.enable = true;
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    git
    vscode
  ];
  system.stateVersion = "26.05";
}
