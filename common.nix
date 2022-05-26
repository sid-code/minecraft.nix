{ pkgs, lib }:
self: super:
with self; {

  fabricProfiles = importJSON ./fabric/profiles.json;
  fabricLibraries = importJSON ./fabric/libraries.json;
  fabricLoaders = importJSON ./fabric/loaders.json;

  fetchJar = name:
    let
      inherit (fabricLibraries.${name}) repo hash;
      splitted = splitString ":" name;
      org = builtins.elemAt splitted 0;
      art = builtins.elemAt splitted 1;
      ver = builtins.elemAt splitted 2;
      path =
        "${replaceStrings [ "." ] [ "/" ] org}/${art}/${ver}/${art}-${ver}.jar";
      url = "${repo}/${path}";
    in pkgs.fetchurl {
      inherit url;
      ${hash.type} = hash.value;
    };
  mkLauncher = baseModulePath: modules:
    let
      final = evalModules {
        modules = modules
          ++ [ ({ _module.args.pkgs = pkgs; }) (import baseModulePath) ];
      };
    in final.config.launcher // {
      withConfig = extraConfig:
        mkLauncher baseModulePath (modules ++ toList extraConfig);
    };

  buildMc = { baseModulePath, buildFabricModules, buildVanillaModules
    , versionInfo, assetsIndex, fabricProfile }:
    let
      fabric = mkLauncher baseModulePath
        (buildFabricModules versionInfo assetsIndex fabricProfile);
    in {
      vanilla =
        mkLauncher baseModulePath (buildVanillaModules versionInfo assetsIndex);
    } // (optionalAttrs (fabricProfile != null) { inherit fabric; });

  mkBuild = { baseModulePath, buildFabricModules, buildVanillaModules }:
    gameVersion: assets:
    let
      versionInfo = importJSON (pkgs.fetchurl { inherit (assets) url sha1; });
      assetsIndex =
        importJSON (pkgs.fetchurl { inherit (versionInfo.assetIndex) url sha1; });
      fabricProfile = fabricProfiles.${gameVersion} or null;
    in buildMc {
      inherit baseModulePath buildFabricModules buildVanillaModules versionInfo
        assetsIndex fabricProfile;
    };
}
