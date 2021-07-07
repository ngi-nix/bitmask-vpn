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
      {
        overlays.bitmask-vpn = final: prev:
          {
            bitmask-vpn = prev.callPackage ./bitmask-vpn.nix {};
          };

        defaultPackage = forAllSystems (system:
          let
            pkgs = import nixpkgs
              { inherit system; overlays = [ self.overlays.bitmask-vpn ]; };
          in
            pkgs.bitmask-vpn
        );
      };
}
