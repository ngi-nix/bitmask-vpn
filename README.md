# bitmask-vpn

upsteam: https://0xacab.org/leap/bitmask-vpn
ngi-nix: https://github.com/ngi-nix/ngi/issues/92

bitmask-vpn is a GUI client to a series of bitmask VPN providers. The GUI is built using Qt and C++, while the backing library is written in Go.

## Using

In order to use this [flake](https://nixos.wiki/wiki/Flakes) you need to have the 
[Nix](https://nixos.org/) package manager installed on your system. Then you can simply run this 
with:

```
$ nix run github:ngi-nix/bitmask-vpn
```

You can also enter a development shell with:

```
$ nix develop github:ngi-nix/bitmask-vpn
$ # Then you need to also patch shebangs, when you enter the bitmask-vpn repository root with:
$ fixShebangs
```

For information on how to automate this process, please take a look at [direnv](https://direnv.net/).


