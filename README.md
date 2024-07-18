# nix-options

This flake exposes an output of `options` which is a naive merge of a number of option values from various nix module sources. It's intended use is for nixd to consume to give auto-suggestions on possible options.

This flake currently follows my own nix-config options and preferences, the hackability of changing it to your own if you are so inclined is not hard at all. Simply expose an array of import targets that you desire to your nix-config output of `common.options.${system}` and change the input of nix-config to your flake reference.

## nixd Features

Take a look at [nixd](https://github.com/nix-community/nixd/blob/main/README.md) to understand _why_ you'd want to use this.

Stealing from nixd's README:
![options-example](https://github.com/nix-community/nixd/assets/36667224/43e00a8e-c2e6-4598-b188-f5e95d708256)

## Context Awareness

The default options exposed are nixosConfiguration, darwinConfiguration and homeManagerConfiguration plus any options I personally utilise for my systems. Because these options likely share values to an extent, be aware that while autocomplete might suggest `users.users.<name>.subUidRanges` is valid on a darwin system, it is not - this hint is stemming from the nixos option of the same name.

Hopefully the future of this space gives us very context aware suggestions, but for now these hints are simply a mash of everything I utilise to speed up my hacking within nix.

## Use in VSCodium

To use this within VSCodium or alike editors, add the following to your user's home-manager module for vscodium:

```nix
programs.vscode.userSettings."nix.serverSettings".nixd = {
    formatting.command = [ "${pkgs.nixfmt}/bin/nixfmt" ];
    "options" = {
    darwin.expr =
        ''(builtins.getFlake "${nix-options}").options.darwin'';
    hm.expr = ''(builtins.getFlake "${nix-options}").options.hm'';
    nixos.expr = ''(builtins.getFlake "${nix-options}").options.nixos'';
    };
};
```

## Why move this to a flake when it existed in my configs already?

Because the original implementation referenced my config's self attribute, it caused re-evaluation _every_ rebuild for my vscodium settings for any changes in code completely non-related to vscodium.

By placing this here, I can govern the reference via flake lock and not have this ugly side-effect occur.
