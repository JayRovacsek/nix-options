{
  description = "Nix option autocompletions for nixd";

  inputs = {
    git-hooks = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:cachix/git-hooks.nix";
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nix-config.url = "github:JayRovacsek/nix-config";
  };

  outputs =
    {
      self,
      git-hooks,
      nixpkgs,
      nix-config,
      ...
    }:
    let
      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      forAllSystems =
        function:
        nixpkgs.lib.genAttrs systems (
          system: function nixpkgs.legacyPackages.${system}
        );
    in
    {
      checks = forAllSystems (pkgs: {
        default = git-hooks.lib.${pkgs.system}.run {
          src = self;
          hooks = {
            deadnix = {
              enable = true;
              settings.edit = true;
            };
            nixfmt-rfc-style = {
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
          packages = with pkgs; [
            deadnix
            nixfmt
            nodePackages.prettier
            statix
          ];
          inherit (self.checks.${pkgs.system}.default) shellHook;
        };
      });

      options = {
        # Merged options are not required anymore after this update:
        # https://github.com/nix-community/vscode-nix-ide/commit/087bd2b70b8c8292a88f4472dd272d56d6bbc6d3
        darwin = nix-config.lib.options.darwin.options;
        home-manager = nix-config.lib.options.home-manager.options;
        nixos = nix-config.lib.options.linux.options;
      };
    };
}
