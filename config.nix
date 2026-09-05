host:
let
  profile = host.profile or "";

  common = {
    git = true;
    gitSshKeys = [ ./modules/ssh/github.com ];
    ssh = true;
    sshKeys = [ ./modules/ssh/github.com ];
    wsl = false;
  };
  os =
    if host.platform == "nixos" then
      { } // (if profile == "graphical" then { } else { })
    else if host.platform == "darwin" then
      { }
    else
      { };
in
common // os // host
