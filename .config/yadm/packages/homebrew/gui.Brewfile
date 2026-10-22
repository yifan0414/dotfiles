apps = ENV.fetch("HOMEBREW_DOTFILES_GUI_APPS", "ghostty kitty squirrel").split
unknown = apps - %w[ghostty kitty squirrel]
abort "Unknown DOTFILES_GUI_APPS: #{unknown.join(' ')}" unless unknown.empty?

apps.each { |app| cask app }
cask "font-maple-mono-cn" if apps.include?("kitty")
