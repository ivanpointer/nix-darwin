{
  description = "Ivan's personal nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
    }:
    let
      configuration =
        { pkgs, ... }:
        let
          primaryUser = "ivanpointer";
          homeDir = "/Users/${primaryUser}";
          npmGlobalPrefix = "${homeDir}/.local/share/npm-global";
          tabbyVersion = "0-unstable-2026-05-23";
          tabbySrc = pkgs.fetchFromGitHub {
            owner = "brendandebeasi";
            repo = "tabby";
            rev = "31417209b59618e324f80141e66381e4b2d6ef7c";
            hash = "sha256-2abp2LKu+PtgFGeksvuaZGRDG5bsJPRxY1gyPu5RzhQ=";
          };
          tabbyBin = pkgs.buildGoModule {
            pname = "tabby-tmux-bin";
            version = tabbyVersion;
            src = tabbySrc;
            vendorHash = null;
            subPackages = [
              "cmd/input-logger"
              "cmd/mousetest"
              "cmd/render-status"
              "cmd/render-status-window"
              "cmd/render-tab"
              "cmd/render-tab-dark-text"
              "cmd/render-tab-v2"
              "cmd/tabby"
            ];
          };
          tabbyTmuxPlugin = pkgs.stdenvNoCC.mkDerivation {
            pname = "tmuxplugin-tabby";
            version = tabbyVersion;
            src = tabbySrc;
            dontBuild = true;
            installPhase = ''
              runHook preInstall

              pluginDir="$out/share/tmux-plugins/tabby"
              mkdir -p "$pluginDir/bin"
              cp -R . "$pluginDir"
              rm -rf "$pluginDir/bin"
              mkdir -p "$pluginDir/bin"
              for bin in ${tabbyBin}/bin/*; do
                ln -s "$bin" "$pluginDir/bin/$(basename "$bin")"
              done

              runHook postInstall
            '';
          };
          npmGlobalPackages = [
            "@openai/codex@latest"
            "@earendil-works/pi-coding-agent@latest"
            "opencode-ai@latest"
            "pi-mcp-extension@latest"
          ];
        in
        {
          nixpkgs.config.allowUnfree = true;

          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            # tmux
            pkgs.tmux
            pkgs.tmuxPlugins.catppuccin
            pkgs.tmuxPlugins.cpu
            pkgs.tmuxPlugins.battery
            tabbyTmuxPlugin

            # neovim
            pkgs.neovim
            pkgs.vimPlugins.LazyVim
            pkgs.vimPlugins.vim-tmux-navigator
            pkgs.tree-sitter

            # LSPs
            pkgs.nil
            pkgs.nodejs
            pkgs.cargo

            pkgs.wget
            pkgs.bat
            pkgs.obsidian
            pkgs.mas # Mac App Store CLI
            pkgs.jq
            pkgs.ripgrep
            pkgs.fd
            pkgs.fzf
            pkgs.fswatch
            pkgs.watchexec
            pkgs.atuin
            pkgs.zoxide
            pkgs.git
            pkgs.lazygit
            pkgs.jujutsu
            pkgs.eza
            pkgs.starship
            pkgs.carapace
            pkgs.sesh
            pkgs.btop
            pkgs.chezmoi
            pkgs._1password-cli
            pkgs.devbox
            (pkgs.azure-cli.withExtensions (with pkgs.azure-cli-extensions; [
              azure-devops
              resource-graph
            ]))
            pkgs.git-credential-manager
            pkgs.gh
            pkgs.terraform
            pkgs.zsh-vi-mode
            pkgs.lua5_1
            pkgs.luarocks

            # QMK
            pkgs.qmk
            pkgs.dos2unix
          ];

          environment.variables.ZSH_VI_MODE_PATH = "${pkgs.zsh-vi-mode}/share/zsh-vi-mode";
          environment.variables.CATPPUCCIN_TMUX_PATH = "${pkgs.tmuxPlugins.catppuccin.rtp}";
          environment.variables.TMUX_CPU_PATH = "${pkgs.tmuxPlugins.cpu.rtp}";
          environment.variables.TMUX_BATTERY_PATH = "${pkgs.tmuxPlugins.battery.rtp}";
          environment.variables.TABBY_TMUX_PATH = "${tabbyTmuxPlugin}/share/tmux-plugins/tabby/tabby.tmux";

          fonts.packages = [
            pkgs.inconsolata
            pkgs.open-sans
            pkgs.nerd-fonts.inconsolata
          ];

          homebrew = {
            enable = true;
            taps = [
              "manaflow-ai/cmux"
            ];
            brews = [
              "docker"
              "docker-compose"
            ];
            casks = [
              "1password"
              "google-chrome"
              "the-unarchiver"
              "yubico-authenticator"
              "ghostty"
              "wezterm"
              "slack"
              "discord"
              "ollama-app"
              "docker-desktop"
              "chatgpt"
              "claude"
              "tg-pro"
              "raindropio"
              "bartender"
              "daisydisk"
              "spotify"
              "expressvpn"
              "notion"
              "elgato-stream-deck"
              "snagit"
              "warp"
              "raycast"
              "ultimaker-cura"
              "steam"
              "raspberry-pi-imager"
              "freecad"
              "hammerspoon"
              "finicky"
              "orcaslicer"
              "bambu-studio"
              "kicad"
              "openscad@snapshot"
              "visual-studio-code"
              "manaflow-ai/cmux/cmux"
            ];
            masApps = {
              "Amphetamine" = 937984704;
              "Azure VPN Client" = 1553936137;
              "Xcode" = 497799835;
            };

            onActivation.cleanup = "zap";
          };

          environment.systemPath = [
            "/opt/homebrew/bin"
            "${npmGlobalPrefix}/bin"
          ];
          environment.variables.NPM_CONFIG_PREFIX = npmGlobalPrefix;

          # Let Determinate Nix handle Nix configuration
          nix.enable = false;

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Enable alternative shell support in nix-darwin.
          # programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";

          system.keyboard = {
            enableKeyMapping = true;
            userKeyMapping = [ ];
          };

          security.pam.services.sudo_local.watchIdAuth = true;
          security.pam.services.sudo_local.reattach = true;

          power.sleep = {
            computer = "never";
            display = 20;
            harddisk = "never";
          };

          # System-level git config: rewrite GitLab HTTPS to SSH
          # Lives at /etc/gitconfig — below ~/.gitconfig so chezmoi can layer on top
          environment.etc.gitconfig.text = ''
            [url "git@github.com:"]
                insteadOf = https://github.com/
          '';

          system.primaryUser = primaryUser;

          # Bootstrap SSH + 1Password config (only if missing)
          # Once chezmoi runs, it owns these files
          system.activationScripts.postActivation.text = ''
                    SSH_DIR="${homeDir}/.ssh"
                    SSH_CONFIG="$SSH_DIR/config"
                    OP_SSH_DIR="${homeDir}/.config/1Password/ssh"
                    OP_AGENT_TOML="$OP_SSH_DIR/agent.toml"

                    # Bootstrap ~/.ssh/config
                    mkdir -p "$SSH_DIR"
                    chmod 700 "$SSH_DIR"
                    chown ${primaryUser}:staff "$SSH_DIR"

                    if [ ! -f "$SSH_CONFIG" ]; then
                      cat > "$SSH_CONFIG" << 'SSHEOF'
            # Bootstrap config — replaced by chezmoi after init
            Host *
                IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
            SSHEOF
                      chmod 600 "$SSH_CONFIG"
                      chown ${primaryUser}:staff "$SSH_CONFIG"
                      echo "Bootstrapped ~/.ssh/config for 1Password SSH agent"
                    fi

                    # Ensure ~/.config/1Password/ssh/agent.toml uses the correct vault
                    mkdir -p "$OP_SSH_DIR"
                    chown -R ${primaryUser}:staff "${homeDir}/.config/1Password"
                    if [ ! -f "$OP_AGENT_TOML" ] || grep -q 'vault = "Personal"' "$OP_AGENT_TOML"; then
                      cat > "$OP_AGENT_TOML" << 'OPEOF'
            # Managed by nix-darwin — replaced by chezmoi after init
            [[ssh-keys]]
            vault = "SSH Credentials"
            OPEOF
                      chown ${primaryUser}:staff "$OP_AGENT_TOML"
                      echo "Enforced 1Password agent.toml vault = SSH Credentials"
                    fi

                    # Install fast-moving npm CLI tools outside nixpkgs so
                    # re-applying the flake refreshes them to their npm target.
                    NPM_GLOBAL_PREFIX="${npmGlobalPrefix}"
                    NPM_GLOBAL_PACKAGES=(${pkgs.lib.escapeShellArgs npmGlobalPackages})
                    mkdir -p "$NPM_GLOBAL_PREFIX"
                    chown -R ${primaryUser}:staff "$NPM_GLOBAL_PREFIX"
                    if [ ''${#NPM_GLOBAL_PACKAGES[@]} -gt 0 ]; then
                      /usr/bin/sudo -u ${primaryUser} -H env \
                        NPM_CONFIG_PREFIX="$NPM_GLOBAL_PREFIX" \
                        PATH="${pkgs.nodejs}/bin:$PATH" \
                        ${pkgs.nodejs}/bin/npm install --global --no-audit --no-fund \
                        "''${NPM_GLOBAL_PACKAGES[@]}"
                    fi

                    # Bootstrap ESP-IDF outside nixpkgs so Espressif's own
                    # installer manages the target toolchains and Python env.
                    ESP_ROOT="${homeDir}/esp"
                    ESP_IDF_DIR="$ESP_ROOT/esp-idf"
                    ESP_IDF_VERSION="v5.4.4"

                    mkdir -p "$ESP_ROOT"
                    chown ${primaryUser}:staff "$ESP_ROOT"

                    if [ ! -d "$ESP_IDF_DIR/.git" ]; then
                      /usr/bin/sudo -u ${primaryUser} -H \
                        ${pkgs.git}/bin/git clone --recursive https://github.com/espressif/esp-idf.git "$ESP_IDF_DIR"
                    fi

                    /usr/bin/sudo -u ${primaryUser} -H env \
                      HOME="${homeDir}" \
                      PATH="${pkgs.git}/bin:${pkgs.gnumake}/bin:${pkgs.python312}/bin:$PATH" \
                      sh -lc "
                        set -e
                        cd '$ESP_IDF_DIR'
                        ${pkgs.git}/bin/git fetch --tags
                        ${pkgs.git}/bin/git checkout '$ESP_IDF_VERSION'
                        ${pkgs.git}/bin/git submodule update --init --recursive
                        ./install.sh esp32
                        python3 tools/idf_tools.py install-python-env --reinstall --features core
                      "

                    # Use full Xcode as the active developer directory once the
                    # App Store install has completed.
                    XCODE_DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
                    if [ -d "$XCODE_DEVELOPER_DIR" ]; then
                      /usr/bin/xcode-select --switch "$XCODE_DEVELOPER_DIR"
                    else
                      echo "Xcode.app is not installed yet; skipping xcode-select"
                    fi
          '';

          system.activationScripts.extraActivation.text =
            let
              srcZip = ./assets/keyboard-layouts/programmer-dvorak.bundle.zip;
            in
            ''
              	  set -euo pipefail

              	  # --- Programmer Dvorak keyboard layout ---
              	  echo "Installing Programmer Dvorak from ${srcZip}"

              	  DVORAK_TMP="$(mktemp -d)"
              	  DVORAK_DST_ROOT="/Library/Keyboard Layouts"
              	  DVORAK_DST_BUNDLE="$DVORAK_DST_ROOT/Programmer Dvorak.bundle"

              	  cleanup() {
              	    rm -rf "$DVORAK_TMP"
              	  }
              	  trap cleanup EXIT

              	  mkdir -p "$DVORAK_DST_ROOT"
              	  rm -rf "$DVORAK_DST_BUNDLE"

              	  ditto -x -k "${srcZip}" "$DVORAK_TMP"

              	  DVORAK_BUNDLE_PATH="$(find "$DVORAK_TMP" -type d -name 'Programmer Dvorak.bundle' -print -quit)"

              	  if [ -z "$DVORAK_BUNDLE_PATH" ]; then
              	    echo "Could not find Programmer Dvorak.bundle inside ${srcZip}" >&2
              	    exit 1
              	  fi

              	  cp -R "$DVORAK_BUNDLE_PATH" "$DVORAK_DST_BUNDLE"

              	  echo "Installed bundle to: $DVORAK_DST_BUNDLE"
              	  ls -la "$DVORAK_DST_BUNDLE"
              	'';

          # https://nix-darwin.github.io/nix-darwin/manual/
          system.defaults = {
            NSGlobalDomain = {
              AppleKeyboardUIMode = 3;
            };

            controlcenter.Sound = true;
            controlcenter.Bluetooth = true;

            hitoolbox.AppleFnUsageType = "Change Input Source";
            CustomUserPreferences = {

              "com.apple.HIToolbox" = {
                AppleEnabledInputSources = [
                  {
                    InputSourceKind = "Keyboard Layout";
                    "KeyboardLayout ID" = 0;
                    "KeyboardLayout Name" = "U.S.";
                  }
                  {
                    InputSourceKind = "Keyboard Layout";
                    "KeyboardLayout ID" = 6454;
                    "KeyboardLayout Name" = "Programmer Dvorak";
                  }
                ];
              };
            };

            dock.autohide = false;
            dock.autohide-delay = 0.16;
            dock.autohide-time-modifier = 1.5;
            dock.orientation = "bottom";
            dock.expose-animation-duration = 1.5;
            dock.expose-group-apps = true;
            dock.magnification = true;
            dock.largesize = 48;
            dock.tilesize = 36;
            dock.mru-spaces = false;
            dock.scroll-to-open = true;
            dock.show-recents = false;
            dock.showAppExposeGestureEnabled = true;
            dock.showLaunchpadGestureEnabled = true;
            dock.showMissionControlGestureEnabled = true;

            # Hot corners on the desktop
            # 1:Disabled 2:MissionControl 3:ApplicationWindows 4:Desktop 5:StartScreenSaver 6:DisableScreenSaver 7:Dashboard 10:PutDisplayToSleep 11:Launchpad 12:NotificationCenter 13:LockScreen 14:QuickNote
            # dock.wvous-bl-corner
            # dock.wvous-br-corner
            # dock.wvous-tl-corner
            # dock.wvous-tr-corner

            dock.persistent-apps = [
              "/Applications/1Password.app"
              "/Applications/Ghostty.app"
              "/Applications/cmux.app"
              "/System/Applications/Calendar.app"
              "/Applications/Microsoft Outlook.app"
              "/System/Applications/Messages.app"
              "/Applications/Google Chrome.app"
              "/Applications/ChatGPT.app"
              "/Applications/Claude.app"
              "/Applications/Warp.app"
              "/Applications/Spotify.app"
              "/Applications/Raindrop.io.app"
            ];

            finder.FXPreferredViewStyle = "clmv";
            finder.FXDefaultSearchScope = "SCcf";
            finder.FXEnableExtensionChangeWarning = false;
            finder.NewWindowTarget = "Home";
            finder.ShowPathbar = true;
            finder.ShowStatusBar = true;
            finder._FXShowPosixPathInTitle = true;
            finder._FXSortFoldersFirst = true;

            iCal.CalendarSidebarShown = true;
            iCal."TimeZone support enabled" = true;

            loginwindow.LoginwindowText = "Jesus is Lord!";
            loginwindow.GuestEnabled = false;
            loginwindow.autoLoginUser = primaryUser;

            menuExtraClock.Show24Hour = true;
            menuExtraClock.ShowDate = 1;

            screensaver.askForPassword = true;
            screensaver.askForPasswordDelay = 300;

            spaces.spans-displays = false;

            trackpad.TrackpadFourFingerHorizSwipeGesture = 2; # 0:disable 2:enable
            trackpad.TrackpadFourFingerPinchGesture = 2;
            trackpad.TrackpadFourFingerVertSwipeGesture = 2;
            trackpad.TrackpadPinch = true;
            trackpad.TrackpadRightClick = true;
            trackpad.TrackpadRotate = true;
            trackpad.TrackpadThreeFingerDrag = true;
            trackpad.TrackpadThreeFingerHorizSwipeGesture = 1; # 0:disable 1:pages 2:full-screen-apps # NOTE: four-finger swipe for apps is enabled, freeing three-finger for pages...
            trackpad.TrackpadTwoFingerFromRightEdgeSwipeGesture = 3; # 0:disable 3:notification-center

          };
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Ivans-MacBook-Pro
      darwinConfigurations."Ivans-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [ configuration ];
      };
    };
}
