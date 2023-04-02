{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.yambar;
  yamlFormat = pkgs.formats.yaml { };

in {
  options = {
    programs.yambar = {
      enable = mkEnableOption "Yambar";

      package = mkPackageOption pkgs "yambar" { };

      settings = mkOption {
        type = yamlFormat.type;
        default = { };
        example = literalExpression ''
          bar = {
            location = "top";
            height = 26;
            background = "00000066";

            right = [
              {
                clock.content = [
                  {
                    string.text = "{time}";
                  }
                ];
              }
            ];
          };
        '';
        description = ''
          Configuration written to
          <filename>$XDG_CONFIG_HOME/yambar/config.yml</filename>.
          See
          <citerefentry>
           <refentrytitle>yambar</refentrytitle>
           <manvolnum>5</manvolnum>
          </citerefentry>
          for options.
        '';
      };

      systemd.enable = mkEnableOption "yambar systemd integration";

      systemd.target = mkOption {
        type = str;
        default = "graphical-session.target";
        example = "sway-session.target";
        description = ''
          The systemd target that will automatically start the yambar service.
          </para>
          <para>
          When setting this value to <literal>"sway-session.target"</literal>,
          make sure to also enable <option>wayland.windowManager.sway.systemdIntegration</option>,
          otherwise the service may never be started.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions =
      [ (hm.assertions.assertPlatform "programs.yambar" pkgs platforms.linux) ];

    home.packages = [ cfg.package ];

    xdg.configFile."yambar/config.yml" = mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "config.yml" cfg.settings;
    };

    systemd.user.services.yambar = mkIf cfg.systemd.enable {
      Unit = {
        Description = "Modular status panel for X11 and Wayland";
        Documentation = "man:yambar(1)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/yambar";
        Restart = "on-failure";
        KillMode = "mixed";
      };

      Install = { WantedBy = [ cfg.systemd.target ]; };
    };
  };

  meta.maintainers = [ maintainers.carpinchomug ];
}
