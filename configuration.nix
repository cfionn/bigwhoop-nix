{ config, pkgs, pkgs-unstable, ... }:
{
  imports = [ ./hardware-configuration.nix ];

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

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "solidus";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/London";

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

  # Enable KDE Plasma 6
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true; # SDDM on Wayland
  };
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "gb";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "uk";

  # Enable CUPS to print documents.
  services.printing.enable = false;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users."fionn" = {
    isNormalUser = true;
    description = "fionn";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" ];
    packages = with pkgs; [];
  };

  programs.fish = {
    enable = true;
    shellAliases = {
      cleanyoself = "sudo nix-env --delete-generations +3 --profile /nix/var/nix/profiles/system";
      upgrade-boot = "sudo nix flake update --flake /run/media/fionn/Storage/bigwhoop-nix/ && sudo nixos-rebuild boot --flake /run/media/fionn/Storage/bigwhoop-nix/#";
      upgrade = "sudo nix flake update --flake /run/media/fionn/Storage/bigwhoop-nix/ && sudo nixos-rebuild switch --flake /run/media/fionn/Storage/bigwhoop-nix/#";
    };
  };

  users.users."fionn".shell = pkgs.fish;

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

  # setup virtualization
  virtualisation.libvirtd.enable = true;

  programs.firefox.enable = true;
  nixpkgs.config.allowUnfree = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };


  environment.sessionVariables = {
    RADV_PERFTEST = "gpl";
    AMD_VULKAN_ICD = "RADV";
    KWIN_EXPLICIT_SYNC = "1"; # if on kernel 6.8+
  };


  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  hardware.xpadneo.enable = true;
  services.udev.packages = [ pkgs.game-devices-udev-rules ];

  services.flatpak.enable = true;

  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; [
    # tools
    git
    vscode
    virt-manager      # replaces gnome-boxes for KDE
    distrobox
    distroshelf
    deja-dup

    # web tools
    thunderbird
    discord
    proton-vpn

    # audio stuff
    audacity
    ardour
    shortwave

    # Web browsers
    (brave.override {
      commandLineArgs = [
        "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder,CanvasOopRasterization"
        "--ignore-gpu-blocklist"
        "--enable-zero-copy"
      ];
    })
    (vivaldi.override {
      commandLineArgs = [
        "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder,CanvasOopRasterization"
        "--ignore-gpu-blocklist"
        "--enable-zero-copy"
      ];
    })

    # gaming tools
    mangohud
    goverlay
    protontricks
    winetricks
    bottles
    lutris
    protonplus

    # vulkan tools
    vulkan-tools
    vulkan-validation-layers

    # unstable packages
    pkgs-unstable.spotify
    pkgs-unstable.heroic
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nix.settings.auto-optimise-store = true;

  system.stateVersion = "26.05";
}