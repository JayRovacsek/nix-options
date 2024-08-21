{
  description = "Nix option autocompletions for nixd";

  inputs = {
    git-hooks = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:cachix/git-hooks.nix";
    };

    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager";
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nix-config.url = "github:JayRovacsek/nix-config";

    nix-darwin = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:lnl7/nix-darwin/master";
    };
  };

  outputs =
    { self, git-hooks, home-manager, nixpkgs, nix-config, nix-darwin, ... }:
    let
      systems =
        [ "aarch64-linux" "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];

      forAllSystems = function:
        nixpkgs.lib.genAttrs systems
        (system: function nixpkgs.legacyPackages.${system});
    in {
      checks = forAllSystems (pkgs: {
        default = git-hooks.lib.${pkgs.system}.run {
          src = self;
          hooks = {
            deadnix = {
              enable = true;
              settings.edit = true;
            };
            nixfmt = {
              enable = true;
              settings.width = 80;
            };
            prettier = {
              enable = true;
              settings.write = true;
            };
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
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          name = "nix-options dev shell";
          packages = with pkgs; [ deadnix nixfmt nodePackages.prettier statix ];
          inherit (self.checks.${pkgs.system}.default) shellHook;
        };
      });

      options = let
        inherit (nixpkgs.lib) nixosSystem;
        inherit (nix-darwin.lib) darwinSystem;
        inherit (home-manager.lib) homeManagerConfiguration;

        # System differences (options) between arch shouldn't exist, but
        # that's going to remain an assumption for now
        nixos = let system = "x86_64-linux";
        in nixosSystem {
          pkgs = import nixpkgs { inherit system; };
          modules = [{
            inherit (nix-config.common.options."${system}-unstable") imports;
          }];
        };

        darwin = let system = "x86_64-darwin";
        in darwinSystem {
          pkgs = import nixpkgs { inherit system; };
          modules = [{
            inherit (nix-config.common.options."${system}-unstable") imports;
          }];
        };

        hm = let system = "x86_64-linux";
        in homeManagerConfiguration {
          pkgs = import nixpkgs { inherit system; };
          modules = [{
            home = {
              stateVersion = "24.05";
              username = "stub";
              homeDirectory = "/";
            };
          }];
        };

      in {
        # Merged options are not required anymore after this update:
        # https://github.com/nix-community/vscode-nix-ide/commit/087bd2b70b8c8292a88f4472dd272d56d6bbc6d3
        darwin = darwin.options;
        hm = hm.options;
        nixos = nixos.options;
      };
    };
}
