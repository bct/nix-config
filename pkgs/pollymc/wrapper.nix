{ lib
, pkgs
, stdenv
, symlinkJoin
, pollymc-unwrapped ? pkgs.pollymc-unwrapped
, wrapQtAppsHook
, addDriverRunpath
, qtbase  # needed for wrapQtAppsHook
, qtsvg
, qtwayland
, xorg
, libpulseaudio
, libGL
, glfw
, openal
, jdk8
, jdk17
, jdk21
, gamemode
, flite
, glxinfo
, pciutils
, udev
, vulkan-loader
, libusb1

, msaClientID ? null
, gamemodeSupport ? stdenv.isLinux
, textToSpeechSupport ? stdenv.isLinux
, controllerSupport ? stdenv.isLinux
, jdks ? [ jdk21 jdk17 jdk8 ]
, additionalLibs ? [ ]
, additionalPrograms ? [ ]
}:
let
  pollymcFinal = pollymc-unwrapped.override {
    inherit msaClientID gamemodeSupport;
  };
in
symlinkJoin {
  name = "pollymc-${pollymcFinal.version}";

  paths = [ pollymcFinal ];

  nativeBuildInputs = [
    wrapQtAppsHook
  ];

  buildInputs = [
    qtbase
    qtsvg
  ]
  ++ lib.optional (lib.versionAtLeast qtbase.version "6" && stdenv.isLinux) qtwayland;

  postBuild = ''
    wrapQtAppsHook
  '';

  qtWrapperArgs =
    let
      runtimeLibs = (with xorg; [
        libX11
        libXext
        libXcursor
        libXrandr
        libXxf86vm
      ])
      ++ [
        # lwjgl
        libpulseaudio
        libGL
        glfw
        openal
        stdenv.cc.cc.lib
        vulkan-loader # VulkanMod's lwjgl

        # oshi
        udev
      ]
      ++ lib.optional gamemodeSupport gamemode.lib
      ++ lib.optional textToSpeechSupport flite
      ++ lib.optional controllerSupport libusb1
      ++ additionalLibs;

      runtimePrograms = [
        xorg.xrandr
        glxinfo
        pciutils # need lspci
      ]
      ++ additionalPrograms;

    in
    [ "--prefix PRISMLAUNCHER_JAVA_PATHS : ${lib.makeSearchPath "bin/java" jdks}" ]
    ++ lib.optionals stdenv.isLinux [
      "--set LD_LIBRARY_PATH ${addDriverRunpath.driverLink}/lib:${lib.makeLibraryPath runtimeLibs}"
      # xorg.xrandr needed for LWJGL [2.9.2, 3) https://github.com/LWJGL/lwjgl/issues/128
      "--prefix PATH : ${lib.makeBinPath runtimePrograms}"
    ];

  inherit (pollymcFinal) meta;
}
