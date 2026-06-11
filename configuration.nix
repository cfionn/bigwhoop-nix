# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').
{ config, pkgs, pkgs-unstable, ... }:
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

  nix.settings.substituters = [ "https://nixos.org" "https://xuyh0120.win" ];
  nix.settings.trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];

  # PICK KERNEL HERE
  # Use latest kernel.
  # Default Kernels
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelPackages = pkgs.linuxPackages_lts;

  # Cachy Kernels
  # boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
  # boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-lts;
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore;

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

  # disable xserver things
  services.xserver.excludePackages = [ pkgs.xterm ];

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

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

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users."fionn" = {
    isNormalUser = true;
    description = "fionn";
    extraGroups = [ "networkmanager" "wheel" "libvirtd"];
    packages = with pkgs; [];
  };

  # enable fish terminal and add some aliases for updating the system
  programs.fish = {
    enable = true;
    shellAliases = {
      cleanyoself = "sudo nix-env --delete-generations +3 --profile /nix/var/nix/profiles/system";
      upgrade-boot = "sudo nix flake update --flake /run/media/fionn/Storage/bigwhoop-nix/ && sudo nixos-rebuild boot --flake /run/media/fionn/Storage/bigwhoop-nix/#";
      upgrade = "sudo nix flake update --flake /run/media/fionn/Storage/bigwhoop-nix/ && sudo nixos-rebuild switch --flake /run/media/fionn/Storage/bigwhoop-nix/#";
    };
  };

  # use default fish shell
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

  # remove gnome packages you dinny want
  environment.gnome.excludePackages = with pkgs; [
    epiphany # browser
    gnome-tour
    gnome-user-docs
    gnome-music
    gnome-characters
    yelp
  ];


  # setup virtualization 
  # Enable Libvirtd
  virtualisation.libvirtd.enable = true;

  # Install firefox.
  programs.firefox.enable = true;
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable Hardware Graphics (VA-API) with Unstable Mesa safely injected
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    package = pkgs-unstable.mesa;
    package32 = pkgs-unstable.pkgsi686Linux.mesa;
  };

  # RADV performance tweaks for RDNA1
  environment.sessionVariables = {
    RADV_PERFTEST = "gpl";     # faster shader compilation, reduces stutter
    AMD_VULKAN_ICD = "RADV";   # prefer RADV over AMDVLK
  };

  # Steam with Proton support
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
    extraCompatPackages = [ pkgs.proton-ge-bin ]; # better Proton for tricky games
  };

  # GameMode — lets games request higher CPU/GPU priority
  programs.gamemode.enable = true;
  # GameScope - enable gamescope compositor
  programs.gamescope.enable = true;

  # Gamepad support
  hardware.xpadneo.enable = true; # Xbox wireless controllers (BT)
  services.udev.packages = [ pkgs.game-devices-udev-rules ]; # broad gamepad udev rules

  # enable docker for distro box and other packages such as packet tracer
  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; [
    # tools
    git
    vscode
    gnome-boxes
    distrobox
    distroshelf

    # web tools
    thunderbird
    discord
    proton-vpn

    # audio stuff
    audacity
    ardour

    # Web browsers overridden with hardware acceleration flags for chromium codecs
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
    mangohud              # in-game performance overlay (fps, temps, frametimes)
    goverlay              # GUI config for MangoHud
    protontricks          # install Windows dependencies for specific Steam games
    winetricks            # same but for non-Steam Wine games
    bottles               # GUI Wine manager for non-Steam games
    lutris                # game launcher (GOG, Epic, etc)
    protonplus            # manages steam versions

    # vulkan tools
    vulkan-tools
    vulkan-validation-layers

    # gnome extensions
    gnomeExtensions.appindicator
    gnomeExtensions.caffeine
    gnomeExtensions.hot-edge
    gnomeExtensions.spotify-controller
    gnomeExtensions.blur-my-shell

    # unstable packages
    pkgs-unstable.spotify
    pkgs-unstable.heroic
  ];

  programs.dconf.profiles.user.databases = [{
    settings = {
      "org/gnome/shell" = {
        # Turn off extension version checking globally
        disable-extension-version-validation = true;

        # Automatically enable your chosen extensions
        enabled-extensions = [
          "appindicatorsupport@rgcjonas.gmail.com" # Fixed the ID here
          "caffeine@patapon.info"
          "hotedge@jonathan.jdoda.ca"
          "spotify-controller@narkagni"
          "blur-my-shell@aunetx"
        ];
      };
    };
  }];

  # Automatic Garbage Collection and Store Optimization
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nix.settings.auto-optimise-store = true;

  system.stateVersion = "26.05"; # Kept relative to your flake release target
}
