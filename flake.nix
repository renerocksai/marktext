
{
  description = "A flake for MarkText with local development setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        marktext = pkgs.callPackage ({ appimageTools, fetchurl, lib }:
          let
            pname = "marktext";
            version = "0.17.1-rene-rc.4";
            src = fetchurl {
              url = "https://github.com/renerocksai/marktext/releases/download/v${version}/marktext-x86_64.AppImage";
              sha256 = "sha256-84xCjFzlH9C+Eq2EbcLCnfXiuXMPzSWcsGR2eUKTRJM=";
            };
            appimageContents = appimageTools.extractType2 {
              inherit pname version src;
            };
          in
          appimageTools.wrapType2 rec {
            inherit pname version src;

            profile = ''
              export LC_ALL=C.UTF-8
            '';
            multiArch = false; # no 32bit needed
            extraPkgs = p: (appimageTools.defaultFhsEnvArgs.multiPkgs p) ++ [
              p.libsecret
              p.xorg.libxkbfile
              # Add any other dependencies here if needed
            ];
            extraInstallCommands = ''
              # Strip version from binary name.
              mv $out/bin/${pname}-${version} $out/bin/${pname}

              install -m 444 -D ${appimageContents}/marktext.desktop $out/share/applications/marktext.desktop
              substituteInPlace $out/share/applications/marktext.desktop \
                --replace "Exec=AppRun" "Exec=${pname} --"

              cp -r ${appimageContents}/usr/share/icons $out/share
            '';

            meta = with lib; {
              description = "A simple and elegant markdown editor, available for Linux, macOS and Windows";
              homepage = "https://marktext.app";
              license = licenses.mit;
              maintainers = with maintainers; [ nh2 eduarrrd ];
              platforms = [ "x86_64-linux" ];
              mainProgram = "marktext";
            };
          }) {};
      in rec
      {
        packages = {
          marktext = marktext;
        };
        defaultPackage = packages.marktext;
        devShell = pkgs.mkShell {
          buildInputs = [ packages.marktext ];
        };
      }
    );
}
