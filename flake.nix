{
  description = "Nix option autocompletions for nixd";

  inputs = {
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager";
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:lnl7/nix-darwin/master";
    };

    nix-config.url = "github:JayRovacsek/nix-config/staging";

    pre-commit-hooks = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:cachix/pre-commit-hooks.nix";
    };
  };

  outputs = { self, home-manager, nixpkgs, nix-config, nix-darwin, ... }:
    let
      systems =
        [ "aarch64-linux" "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];

      forAllSystems = function:
        nixpkgs.lib.genAttrs systems
        (system: function nixpkgs.legacyPackages.${system});

    in {
      checks = forAllSystems (pkgs: {
        default = self.checks.${pkgs.system}.pre-commit;

        pre-commit = self.inputs.pre-commit-hooks.lib.${pkgs.system}.run {
          src = self;
          hooks = {
            # Builtin hooks
            deadnix.enable = true;
            nixfmt.enable = true;
            prettier.enable = true;
            statix.enable = true;
            typos.enable = true;

            # Custom hooks
            statix-write = {
              enable = true;
              name = "Statix Write";
              entry = "${pkgs.statix}/bin/statix fix";
              language = "system";
              pass_filenames = false;
            };
          };

          # Settings for builtin hooks, see also: https://github.com/cachix/pre-commit-hooks.nix/blob/master/modules/hooks.nix
          settings = {
            deadnix.edit = true;
            nixfmt.width = 80;
            prettier.write = true;
          };
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          name = "nix-options dev shell";
          packages = with pkgs; [ deadnix nixfmt nodePackages.prettier statix ];
          inherit (self.checks.${pkgs.system}.pre-commit) shellHook;
        };
      });

      lib.merge = builtins.foldl' nixpkgs.lib.recursiveUpdate { };

      options = let
        inherit (self.lib) merge;
        inherit (nixpkgs.lib) nixosSystem;
        inherit (nix-darwin.lib) darwinSystem;
        inherit (home-manager.lib) homeManagerConfiguration;

        # System differences (options) between arch shouldn't exist, but
        # that's going to remain an assumption for now
        nix-stub = let system = "x86_64-linux";
        in nixosSystem {
          inherit system;
          pkgs = import nixpkgs { inherit system; };
          modules = [{
            inherit (nix-config.common.options."${system}-unstable") imports;
            # imports = [
            #   ../options/headscale
            #   ../options/nix
            #   ../options/ssh
            # ];
          }];
        };

        darwin-stub = let system = "x86_64-darwin";
        in darwinSystem {
          inherit system;
          pkgs = import nixpkgs { inherit system; };
          modules = [{
            inherit (nix-config.common.options."${system}-unstable") imports;

            # imports = [
            #   ../options/dockutil
            #   ../options/headscale
            #   ../options/nix
            # ];
          }];
        };

        home-manager-stub = let system = "x86_64-linux";
        in homeManagerConfiguration {
          pkgs = import nixpkgs { inherit system; };
          modules = [{
            home = {
              stateVersion = "23.11";
              username = "stub";
              homeDirectory = "/";
            };
          }];
        };

      in merge [
        nix-stub.options
        darwin-stub.options
        home-manager-stub.options
      ];
    };
}
