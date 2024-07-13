{
  inputs = {
    # Use git+ssh protocol because it's a private repository
    # See https://discourse.nixos.org/t/nix-flakes-and-private-repositories/12014
    nix-ml-ops.url = "github:Atry/nix-ml-ops";
    nix-ml-ops.inputs.systems.url = "github:nix-systems/default";

    blip_models_model_base_caption_capfilt_large = {
      url = "https://www.modelscope.cn/models/popatry/BLIP/resolve/master/models/model_base_caption_capfilt_large.pth";
      flake = false;
    };
    stable-diffusion_v2-1_768-ema-pruned_safetensors = {
      url = "https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.safetensors?download=true";
      flake = false;
    };
    stable-diffusion_v1-5-pruned-emaonly_safetensors = {
      url = "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors?download=true";
      flake = false;
    };
    StableSR_webui_768v_139_ckpt = {
      url = "https://huggingface.co/Iceclear/StableSR/resolve/main/webui_768v_139.ckpt?download=true";
      flake = false;
    };
  };
  outputs = inputs:
    inputs.nix-ml-ops.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.nix-ml-ops.flakeModules.devcontainer
        inputs.nix-ml-ops.flakeModules.nixIde
        inputs.nix-ml-ops.flakeModules.nixLd
        inputs.nix-ml-ops.flakeModules.pythonVscode
        inputs.nix-ml-ops.flakeModules.ldFallbackManylinux
        inputs.nix-ml-ops.flakeModules.cuda
        inputs.nix-ml-ops.flakeModules.linkNvidiaDrivers
      ];
      perSystem = { pkgs, config, lib, system, ... }: {
        ml-ops.devcontainer = {

          LD_LIBRARY_PATH = lib.mkMerge [
            # `glib` and `libGL` are opencv-python dependencies. They must be added to `$LD_LIBRARY_PATH`, unlike other libraries solved by $LD_AUDIT, because `opencv-python` does not respect $LD_AUDIT.
            "${pkgs.glib.out}/lib"
            "${pkgs.libGL}/lib"
          ];
          nixago.requests = {

            "models/BLIP/model_base_caption_capfilt_large.pth" = {
              data = { };
              engine = { data, output, ... }: inputs.blip_models_model_base_caption_capfilt_large;
            };
            "extensions/sd-webui-stablesr/models/webui_768v_139.ckpt" = {
              data = { };
              engine = { data, output, ... }: inputs.StableSR_webui_768v_139_ckpt;
            };
            "models/Stable-diffusion/v1-5-pruned-emaonly.safetensors" = {
              data = { };
              engine = { data, output, ... }: inputs.stable-diffusion_v1-5-pruned-emaonly_safetensors;
            };
            "models/Stable-diffusion/v2-1_768-ema-pruned.safetensors" = {
              data = { };
              engine = { data, output, ... }: inputs.stable-diffusion_v2-1_768-ema-pruned_safetensors;
            };
          };
          devenvShellModule = {
            languages = {
              c.enable = true;
              python = {
                enable = true;
                venv = {
                  enable = true;
                  requirements = lib.mkMerge [
                    (builtins.readFile ./requirements.txt)
                    "xformers"
                    "insightface"
                  ];
                };
              };
            };
          };
        };

      };
    };
}
