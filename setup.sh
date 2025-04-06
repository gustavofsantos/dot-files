#!/usr/bin/env zsh

echo "Linking home files..."
ln -sf "$(pwd)/.gitconfig" "$HOME/.gitconfig"
ln -sf "$(pwd)/.githelpers" "$HOME/.githelpers"
ln -sf "$(pwd)/.gitmessage" "$HOME/.gitmessage"
ln -sf "$(pwd)/.gitthemes" "$HOME/.gitthemes"
ln -sf "$(pwd)/.ideavimrc" "$HOME/.ideavimrc"
ln -sf "$(pwd)/.psqlrc" "$HOME/.psqlrc"
ln -sf "$(pwd)/.zprofile" "$HOME/.zprofile"
ln -sf "$(pwd)/.zshenv" "$HOME/.zshenv"
ln -sf "$(pwd)/.zshrc" "$HOME/.zshrc"
echo "Linking home files... OK"

echo "Linking bin files..."
cd bin && find . -type f -exec ln -sf "$(pwd)/{}" "$HOME/.local/bin/{}" \; && cd ..
echo "Linking bin files... OK"

echo "Linking xdg config..."
stow config
echo "Linking xdg config... OK"
