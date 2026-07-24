{ modulesPath, pkgs, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = false;

  networking.hostName = "shared";
  networking.useDHCP = true;

  swapDevices = [
    {
      device = "/swapfile";
      size = 4096;
    }
  ];

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      AuthorizedKeysFile = ".ssh/authorized_keys /etc/ssh/authorized_keys.d/%u";
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  services.qemuGuest.enable = true;

  environment.systemPackages = with pkgs; [
    curl
    git
    htop
    python3
    tmux
    vim
  ];

  networking.firewall.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.optimise.automatic = true;

  system.stateVersion = "26.05";
}
