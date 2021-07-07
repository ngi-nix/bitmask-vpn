{ fetchFromGitHub
, buildGoModule
, stdenv
, lib

, qt5
, libsForQt5

, makeWrapper
, go
, which
, python3
, openvpn
, iptables
}:

let
  version = "0.21.6";
  bitmask-src = fetchFromGitHub {
    owner = "MagicRB";
    repo = "bitmask-vpn";
    rev = "d0dfbf9ddc4aa8639ab31745516988c1937c7f77";
    sha256 = "sha256-2iOV8PHXS07aGR98z7AALwIZoAK/+9eTFLGexHGueBw=";
  };
  # prev.fetchFromGitLab {
  #   domain = "0xacab.org";
  #   owner = "leap";
  #   repo = "bitmask-vpn";
  #   rev = "0.21.6";
  #   sha256 = "sha256-LMz+ZgQVFGujoLA8rlyZ3VnW/NSlPipD5KwCe+cFtnY=";
  # };

  libgoshim = buildGoModule {
    name = "bitmask-stuff";
    inherit version;

    vendorSha256 = null;

    doCheck = false;

    subPackages = [
      "pkg/backend"
    ];

    postBuild = ''
      make generate
      go build -buildmode=c-archive -o $out/lib/libgoshim.a gui/backend.go
    '';

    src = bitmask-src;
  };
in
stdenv.mkDerivation {
  name = "bitmask-gui";
  inherit version;

  buildPhase =
    let
      escapePath = path: builtins.replaceStrings ["/"] ["\\/"] (toString path);
    in
      ''
        cp bitmask.pro gui

        ln -s ${libgoshim}/lib gui/lib
        sed -i 's/\/usr\/bin\/env/'"$(which env | sed 's/\//\\\//gm')"'/' ./branding/scripts/* ./gui/build.sh
        make build_gui
      '';

  buildInputs = with qt5; [ qtbase qttools qtquickcontrols2 libsForQt5.qtinstaller libgoshim ];
  nativeBuildInputs = with qt5; [ makeWrapper go wrapQtAppsHook which python3 ];

  installPhase = ''
      mkdir -p $out/bin

      install -Dm755 build/qt/release/riseup-vpn $out/bin/riseup-vpn
      install -Dm755 helpers/bitmask-root $out/bin/bitmask-root
      install -Dm0644 helpers/se.leap.bitmask.policy $out/share/polkit-1/actions/se.leap.bitmask.policy

      wrapProgram $out/bin/riseup-vpn --prefix PATH : $out/bin
      wrapProgram $out/bin/bitmask-root --prefix PATH : ${lib.makeBinPath [ openvpn iptables python3 ]}
    '';

  src = bitmask-src;
}
