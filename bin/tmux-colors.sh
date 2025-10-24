#!/usr/bin/env bash
# Display all 256 terminal colors and their indexes for tmux customization

echo "Standard 16 colors:"
for i in {0..15}; do
  printf "\x1b[48;5;%sm %3s \x1b[0m" "$i" "$i"
  if (( (i + 1) % 8 == 0 )); then
    echo
  fi
done

echo
echo "Colors 16–231 (6×6×6 RGB cube):"
for i in {16..231}; do
  printf "\x1b[48;5;%sm %3s \x1b[0m" "$i" "$i"
  if (( (i - 15) % 6 == 0 )); then
    echo
  fi
done

echo
echo "Grayscale ramp (232–255):"
for i in {232..255}; do
  printf "\x1b[48;5;%sm %3s \x1b[0m" "$i" "$i"
  if (( (i - 231) % 12 == 0 )); then
    echo
  fi
done
echo
