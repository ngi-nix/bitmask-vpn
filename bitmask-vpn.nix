{ fetchFromGitLab
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
, iproute
}:

let
  version = "0.21.6";
  src = fetchFromGitLab {
    domain = "0xacab.org";
    owner = "leap";
    repo = "bitmask-vpn";
    rev = "0.21.6";
    sha256 = "sha256-LMz+ZgQVFGujoLA8rlyZ3VnW/NSlPipD5KwCe+cFtnY=";
  };

  libgoshim = buildGoModule {
    name = "bitmask-stuff";
    inherit version src;

    vendorSha256 = null;

    doCheck = false;

    patches = [ ./patches/0001-Fix-random-hardcoded-paths-for-NixOS-packaging.patch ];

    subPackages = [
      "pkg/backend"
    ];

    postBuild = ''
      make generate
      go build -buildmode=c-archive -o $out/lib/libgoshim.a gui/backend.go
    '';

    enableParallelBuilding = true;
  };
in
stdenv.mkDerivation {
  name = "bitmask-gui";
  inherit version src;

  buildPhase =
    ''
      cp bitmask.pro gui

      ln -s ${libgoshim}/lib gui/lib
      patchShebangs --build ./branding/scripts/ ./gui/build.sh
      make build_gui
    '';

  patches = [ ./patches/0001-Fix-random-hardcoded-paths-for-NixOS-packaging.patch ];

  buildInputs = with qt5;
    [ qtbase qttools qtquickcontrols2 libsForQt5.qtinstaller libgoshim ];
  nativeBuildInputs = with qt5; [ makeWrapper go wrapQtAppsHook which python3 ];

  installPhase = ''
      mkdir -p $out/bin

      install -Dm755 build/qt/release/riseup-vpn $out/bin/riseup-vpn
      install -Dm755 helpers/bitmask-root $out/bin/bitmask-root
      install -Dm0644 helpers/se.leap.bitmask.policy $out/share/polkit-1/actions/se.leap.bitmask.policy

      wrapProgram $out/bin/riseup-vpn --prefix PATH : $out/bin:${lib.makeBinPath [ iproute ]}
      wrapProgram $out/bin/bitmask-root --prefix PATH : ${lib.makeBinPath [ openvpn iptables python3 ]}
    '';

  enableParallelBuilding = true;

  meta = with lib; {
    homepage = "https://0xacab.org/leap/bitmask-vpn";
    description = "A golang implementation of the Bitmask VPN client, displaying a systray icon as a state indicator and control.";
    mainProgram = "riseup-vpn";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
    maintainers = [ maintainers.magic_rb ];
  };
}
