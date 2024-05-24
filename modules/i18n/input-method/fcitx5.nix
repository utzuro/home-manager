{ config, pkgs, lib, ... }:

with lib;

let
  im = config.i18n.inputMethod;
  cfg = im.fcitx5;
  fcitx5Package = pkgs.libsForQt5.fcitx5-with-addons.override { inherit (cfg) addons; };
  settingsFormat = pkgs.formats.ini { };
in {
  options = {
    i18n.inputMethod.fcitx5 = {
      addons = mkOption {
        type = with types; listOf package;
        default = [ ];
        example = literalExpression "with pkgs; [ fcitx5-rime ]";
        description = ''
          Enabled Fcitx5 addons.
        '';
      };
      waylandFrontend = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Use the Wayland input method frontend.
          See [Using Fcitx 5 on Wayland](https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland).
        '';
      };
      quickPhrase = mkOption {
        type = with types; attrsOf str;
        default = { };
        example = literalExpression ''
          {
            smile = "（・∀・）";
            angry = "(￣ー￣)";
          }
        '';
        description = "Quick phrases.";
      };
      quickPhraseFiles = mkOption {
        type = with types; attrsOf path;
        default = { };
        example = literalExpression ''
          {
            words = ./words.mb;
            numbers = ./numbers.mb;
          }
        '';
        description = "Quick phrase files.";
      };
      settings = {
        globalOptions = lib.mkOption {
          type = lib.types.submodule {
            freeformType = settingsFormat.type;
          };
          default = { };
          description = ''
            The global options in `config` file in ini format.
          '';
        };
        inputMethod = lib.mkOption {
          type = lib.types.submodule {
            freeformType = settingsFormat.type;
          };
          default = { };
          description = ''
            The input method configure in `profile` file in ini format.
          '';
        };
        addons = lib.mkOption {
          type = with lib.types; (attrsOf anything);
          default = { };
          description = ''
            The addon configures in `conf` folder in ini format with global sections.
            Each item is written to the corresponding file.
          '';
          example = literalExpression "{ pinyin.globalSection.EmojiEnabled = \"True\"; }";
        };
      };
      ignoreUserConfig = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Ignore the user configures. **Warning**: When this is enabled, the
          user config files are totally ignored and the user dict can't be saved
          and loaded.
        '';
      };
    };
  };

  config = mkIf (im.enabled == "fcitx5") {
    i18n.inputMethod.package = fcitx5Package;

    home.sessionVariables = {
      GLFW_IM_MODULE = "ibus"; # IME support in kitty
      XMODIFIERS = "@im=fcitx";
      QT_PLUGIN_PATH =
        "$QT_PLUGIN_PATH\${QT_PLUGIN_PATH:+:}${fcitx5Package}/${pkgs.qt6.qtbase.qtPluginPrefix}";
    } // lib.optionalAttrs (!cfg.waylandFrontend) {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
    };

    systemd.user.services.fcitx5-daemon = {
      Unit = {
        Description = "Fcitx5 input method editor";
        PartOf = [ "graphical-session.target" ];
      };
      Service.ExecStart = "${fcitx5Package}/bin/fcitx5";
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };

}
