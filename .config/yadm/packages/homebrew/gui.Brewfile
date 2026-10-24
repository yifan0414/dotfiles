apps = ENV.fetch("HOMEBREW_DOTFILES_GUI_APPS", "kitty fcitx5 zotero").split
unknown = apps - %w[kitty fcitx5 zotero]
abort "Unknown DOTFILES_GUI_APPS: #{unknown.join(' ')}" unless unknown.empty?

cask "kitty" if apps.include?("kitty")
cask "font-maple-mono-cn" if apps.include?("kitty")
cask "zotero" if apps.include?("zotero")
# Bootstrap installs Fcitx5 with the upstream Rime installer and the Frost scheme.
