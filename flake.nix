{
  inputs = {
    nixpkgs.url = "nixpkgs";
  };

  outputs = { self, nixpkgs }@inputs:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems' = systems: fun: nixpkgs.lib.genAttrs systems fun;
      forAllSystems = forAllSystems' supportedSystems;
    in
      with nixpkgs.lib;
      {
        overlays.bitmask-vpn = final: prev:
          {
            bitmask-vpn = prev.callPackage ./bitmask-vpn.nix {};
          };

        overlay = self.overlays.bitmask-vpn;

        packages = forAllSystems (system:
          { bitmask-vpn = self.defaultPackage.${system}; }
        );

        defaultPackage = forAllSystems (system:
          let
            pkgs = import nixpkgs
              { inherit system; overlays = [ self.overlays.bitmask-vpn ]; };
          in
            pkgs.bitmask-vpn
        );

        apps = self.packages;

        defaultApp = self.defaultPackage;

        devShell = forAllSystems (system:
          let
            pkgs = import nixpkgs
              { inherit system;
                overlays = mapAttrsToList (_: id) self.overlays;
              };
          in
            pkgs.mkShell {
              buildInputs = with pkgs.qt5; with pkgs;
                [ qtbase qttools qtquickcontrols2 libsForQt5.qtinstaller ];
              nativeBuildInputs = with pkgs.qt5; with pkgs;
                [ makeWrapper go wrapQtAppsHook which python3
                  openvpn iptables
                ];

              shellHook = ''
                function fixShebangs()
                {
                  patchShebangs --build ./branding/scripts/ ./gui/build.sh
                }
              '';
            }
        );
      };
}
