apps = ENV.fetch("HOMEBREW_DOTFILES_GUI_APPS", "kitty fcitx5").split
unknown = apps - %w[kitty fcitx5]
abort "Unknown DOTFILES_GUI_APPS: #{unknown.join(' ')}" unless unknown.empty?

cask "kitty" if apps.include?("kitty")
cask "font-maple-mono-cn" if apps.include?("kitty")
# Fcitx5 uses its upstream installer, launched separately by bootstrap.
