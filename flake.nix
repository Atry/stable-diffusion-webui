{
  inputs = {
    # Use git+ssh protocol because it's a private repository
    # See https://discourse.nixos.org/t/nix-flakes-and-private-repositories/12014
    nix-ml-ops.url = "github:Atry/nix-ml-ops";
    nix-ml-ops.inputs.systems.url = "github:nix-systems/default";

    stable-diffusion_v2-1_768-ema-pruned_safetensors = {
      url = "https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.safetensors?download=true";
      flake = false;
    };
  };
  outputs = inputs @ { nix-ml-ops, ... }:
    nix-ml-ops.lib.mkFlake { inherit inputs; } {
      imports = [
        nix-ml-ops.flakeModules.devcontainer
        nix-ml-ops.flakeModules.nixIde
        nix-ml-ops.flakeModules.nixLd
        nix-ml-ops.flakeModules.pythonVscode
        nix-ml-ops.flakeModules.ldFallbackManylinux
      ];
      perSystem = { pkgs, config, lib, system, ... }: {
        ml-ops.devcontainer = {

          LD_LIBRARY_PATH = lib.mkMerge [
            # `glib` and `libGL` are opencv-python dependencies. They must be added to `$LD_LIBRARY_PATH`, unlike other libraries solved by $LD_AUDIT, because `opencv-python` does not respect $LD_AUDIT.
            "${pkgs.glib.out}/lib"
            "${pkgs.libGL}/lib"
          ];
          nixago.requests."models/Stable-diffusion/v2-1_768-ema-pruned.safetensors" = {
            data = {};
            engine = { data, output, ... }: inputs.stable-diffusion_v2-1_768-ema-pruned_safetensors;
          };
          devenvShellModule = {
            languages = {
              python = {
                enable = true;
                venv = {
                  enable = true;
                  requirements = ''
                    ${builtins.readFile ./requirements.txt}
                    xformers
                  '';
                };
              };
            };
          };
        };

      };
    };
}
