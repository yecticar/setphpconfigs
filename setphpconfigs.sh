#!/bin/bash

# Function that verifies the existence of the folder
validate_folder_existence() {
  if [ ! -d "$1" ]; then
    echo "$1 does not exist, exiting..."
    exit 1
  fi

  return 0
}

if [ "$(id -u)" != 0 ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

## Loads config file if the script has been made as a symbolic link
# First reference the executed file
cd "$(dirname "$0")" || exit 1
# Second fetch the original file if exists
ORIGINAL_PATH="$(dirname "$(greadlink "$0")")"
export ORIGINAL_PATH
# Loads config.local.sh if exists, else, requires you to create one
if [[ -f "$ORIGINAL_PATH/config.local.sh" ]]; then
  source "$ORIGINAL_PATH/config.local.sh"
else
  echo "Loading the default options, you may want to change to your custom"
  echo "options creating a local config file: \`cp config.sh config.local.sh\`"
  source "$ORIGINAL_PATH/config.sh"
fi

OPTIONS_AVAILABLE=("homebrew" "macports" "Custom" "Quit")

echo "What package manager are you using?:"
select opt in "${OPTIONS_AVAILABLE[@]}"; do
  echo "Executing $opt configurations..."

  case $REPLY in
    1)
      # For homebrew we need to verify mac architecture because the file structure is different
      if [ "$(uname -m)" = "arm64" ]; then
        echo "Apple Silicon (ARM)"
        CONFIG_ROOT="/opt/homebrew/etc/php"
      else
        echo "Intel (x86_64)"
        CONFIG_ROOT="/usr/local/etc/php"
      fi
      export CONFIG_ROOT

      validate_folder_existence "$CONFIG_ROOT"
      "$ORIGINAL_PATH/configure_files.sh"
      break
      ;;
    2)
      CONFIG_ROOT="/opt/local/etc"
      export CONFIG_ROOT

      validate_folder_existence "$CONFIG_ROOT"
      "$ORIGINAL_PATH/configure_files.sh"
      break
      ;;
    3)
      echo "You must enter the ABSOLUTE path where all the php configurations are."
      echo "Examples:"
      echo "1. /Users/username/etc (if the configurations go directly in the etc folder)"
      echo "2. /Users/username/etc/php (if the configurations go inside a custom folder)"
      read -rp "Enter your configuration path: " CONFIG_ROOT
      export CONFIG_ROOT

      validate_folder_existence "$CONFIG_ROOT"
      "$ORIGINAL_PATH/configure_files.sh"
      break
      ;;
    4)
      echo "Exiting..."
      exit 0
      ;;
    *)
      echo "Invalid option. Try again."
      ;;
  esac
done

exit 0
