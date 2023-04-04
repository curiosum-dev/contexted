{
  description = "Development environment";

  inputs = {
      nixpkgs = { url = "github:NixOS/nixpkgs/nixpkgs-unstable"; };
      flake-utils = { url = "github:numtide/flake-utils"; };
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        inherit (nixpkgs.lib) optional;
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
          devShell = pkgs.mkShell
          {
            buildInputs =
              (with pkgs; [
                elixir_1_14
                elixir_ls
                hex
                rebar3
                glibcLocales
                nodejs
                inotify-tools
                # needed for emacs to unzip elixir-ls
                unzip
              ]);

              shellHook = ''
                echo "Setting up mix"
                # this allows mix to work on the local directory
                mkdir -p .nix-mix
                mkdir -p .nix-hex
                export MIX_HOME=$PWD/.nix-mix
                export HEX_HOME=$PWD/.nix-hex
                export PATH=$MIX_HOME/bin:$PATH
                export PATH=$HEX_HOME/bin:$PATH
                export LANG=en_US.UTF-8
                export PATH=$PATH:$(pwd)/_build/pip_packages/bin
                export ERL_AFLAGS="-kernel shell_history enabled"
            '';
          };
      }
    );
}
