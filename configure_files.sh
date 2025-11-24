#!/bin/bash

configure_version() {
  # The first parameter given to this script MUST be the VERSION separated by dot
  # e.g.: 7.4
  VERSION="${1:-.}"
  MAJOR_VERSION=${VERSION:0:1}
  MINOR_VERSION=${VERSION:2:2}

  FOLDER="${2:-.}"

  # Message of starting configuration
  echo "Configuring PHP $VERSION version..."

  # php.ini CONFIGURATION
  # Check if a network connection exists
  if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1 || ping -c 1 -t 2 1.1.1.1 >/dev/null 2>&1; then
    # get the configuration file for the version required from gitlab
    URL_PHP_INI_DEVELOPMENT="https://raw.githubusercontent.com/php/php-src/PHP-$VERSION/php.ini-development"
    echo "$CONFIG_ROOT/$FOLDER/php.ini-development"
    curl -fsSL "$URL_PHP_INI_DEVELOPMENT" -o "$CONFIG_ROOT/$FOLDER/php.ini-development" || {
      echo "Failed to download $URL_PHP_INI_DEVELOPMENT"
      exit 1
    }
  else
    if [ ! -f "$CONFIG_ROOT/$FOLDER/php.ini-development" ]; then
      echo "As there is no internet connection and no php.ini-development file found"
      echo "A backup will be made as php.ini-development"
      # Backup the configuration file and make it as the default one
      cp "$CONFIG_ROOT/$FOLDER/php.ini" "$CONFIG_ROOT/$FOLDER/php.ini-development"
    fi
  fi

  # Copy the default configuration file to the one to be modified
  cp "$CONFIG_ROOT/$FOLDER/php.ini-development" "$CONFIG_ROOT/$FOLDER/php.ini"

  # Set the file permissions to the configuration parent folder
  OWNER=$(stat -f "%Su" "$CONFIG_ROOT/$FOLDER")
  GROUP=$(stat -f "%Sg" "$CONFIG_ROOT/$FOLDER")
  # Restore the good the permissions
  chown -R "$OWNER:$GROUP" "$CONFIG_ROOT/$FOLDER"

  # Start modifying the configuration options
  # Modify the memory_limit
  gsed -i -E "s/^;?\s*memory_limit.*$/memory_limit = $MEMORY_LIMIT/" "$CONFIG_ROOT/$FOLDER/php.ini"
  # Modify the post_max_size
  gsed -i -E "s/^;?\s*post_max_size.*$/post_max_size = $POST_MAX_SIZE/" "$CONFIG_ROOT/$FOLDER/php.ini"
  # Modify the upload_max_filesize
  gsed -i -E "s/^;?\s*upload_max_filesize.*$/upload_max_filesize = $POST_MAX_SIZE/" "$CONFIG_ROOT/$FOLDER/php.ini"

  # Modify the date.timezone
  gsed -i -E "s/^;?\s*date.timezone.*$/date.timezone = $DATE_TIMEZONE/" "$CONFIG_ROOT/$FOLDER/php.ini"

  # Modify the pdo_mysql.default_socket
  gsed -i -E "s/^;?\s*pdo_mysql.default_socket.*$/pdo_mysql.default_socket = $PDO_MYSQL_DEFAULT_SOCKET/" "$CONFIG_ROOT/$FOLDER/php.ini"
  # Modify the mysqli.default_socket
  gsed -i -E "s/^;?\s*mysqli.default_socket.*$/mysqli.default_socket = $MYSQLI_DEFAULT_SOCKET/" "$CONFIG_ROOT/$FOLDER/php.ini"

  # Modify the curl.cainfo
  gsed -i -E "s/^;?\s*curl.cainfo.*$/;curl.cainfo = $CURL_CAINFO/" "$CONFIG_ROOT/$FOLDER/php.ini"
  # Modify the openssl.cafile
  gsed -i -E "s/^;?\s*openssl.cafile.*$/;curl.cainfo = $OPENSSL_CAFILE/" "$CONFIG_ROOT/$FOLDER/php.ini"

  # Added the Xdebug configuration
  cat <<EOF >> "$CONFIG_ROOT/$FOLDER/php.ini"

[xdebug]
;xdebug.mode = develop,coverage,debug,gcstats,profile,trace
xdebug.mode = debug,coverage
xdebug.client_port = 9003
xdebug.var_display_max_depth = -1
xdebug.var_display_max_children = -1
xdebug.var_display_max_data = -1
EOF

  # Check if php-fpm is installed before trying to modify it
  if [ ! -f "$CONFIG_ROOT/$FOLDER/php-fpm.conf.default" ] || [ ! -d "$CONFIG_ROOT/$FOLDER/php-fpm.d" ]; then
    echo "PHP-FPM for version $VERSION not found"
    return 0
  fi
  # php-fpm CONFIGURATION
  # Copy the default configuration files to the ones to be modified
  cp "$CONFIG_ROOT/$FOLDER/php-fpm.conf.default" "$CONFIG_ROOT/$FOLDER/php-fpm.conf"
  cp "$CONFIG_ROOT/$FOLDER/php-fpm.d/www.conf.default" "$CONFIG_ROOT/$FOLDER/php-fpm.d/www.conf"

  # Modify the user
  gsed -i -E "s/^;?\s*user\s*=.*$/user = $WWW_CONF_USER/" "$CONFIG_ROOT/$FOLDER/php-fpm.d/www.conf"
  # Modify the group
  gsed -i -E "s/^;?\s*group\s*=.*$/group = $WWW_CONF_GROUP/" "$CONFIG_ROOT/$FOLDER/php-fpm.d/www.conf"

  # Modify the listen
  if [ -n "${WWW_CONF_LISTEN_SOCKET_BASE_PATH}" ]; then
    WWW_CONF_LISTEN_SOCKET_PATH="$WWW_CONF_LISTEN_SOCKET_BASE_PATH\/php-fpm-$MAJOR_VERSION.$MINOR_VERSION.sock"
    gsed -i -E "s/^;?\s*listen\s*=.*$/listen = $WWW_CONF_LISTEN_SOCKET_PATH/" "$CONFIG_ROOT/$FOLDER/php-fpm.d/www.conf"
  elif [ -n "${WWW_CONF_LISTEN_SOCKET_BASE_URI}" ]; then
    WWW_CONF_LISTEN_SOCKET_URI="$WWW_CONF_LISTEN_SOCKET_BASE_URI$MAJOR_VERSION$MINOR_VERSION"
    gsed -i -E "s/^;?\s*listen\s*=.*$/listen = $WWW_CONF_LISTEN_SOCKET_URI/" "$CONFIG_ROOT/$FOLDER/php-fpm.d/www.conf"
  else
    echo "Listener not implemented, consider reviewing the configuration after finishing as it may not be fully configured."
    echo "Run: cat $CONFIG_ROOT/$FOLDER/php-fpm.d/www.conf | grep listen"
  fi
  # Modify the listen.owner
  gsed -i -E "s/^;?\s*listen.owner\s*=.*$/listen.owner = $WWW_CONF_LISTEN_OWNER/" "$CONFIG_ROOT/$FOLDER/php-fpm.d/www.conf"
  # Modify the listen.group
  gsed -i -E "s/^;?\s*listen.group\s*=.*$/listen.group = $WWW_CONF_LISTEN_GROUP/" "$CONFIG_ROOT/$FOLDER/php-fpm.d/www.conf"
  # Modify the listen.mode
  gsed -i -E "s/^;?\s*listen.mode\s*=.*$/listen.mode = $WWW_CONF_LISTEN_MODE/" "$CONFIG_ROOT/$FOLDER/php-fpm.d/www.conf"

  # Modify the pm
  gsed -i -E "s/^;?\s*pm\s*=.*$/pm = $PM/" "$CONFIG_ROOT/$FOLDER/php-fpm.d/www.conf"
  # Modify the pm.max_children
  gsed -i -E "s/^;?\s*pm.max_children\s*=.*$/pm.max_children = $PM_MAX_CHILDREN/" "$CONFIG_ROOT/$FOLDER/php-fpm.d/www.conf"

  if [ "$PM" = "static" ]; then
    # Modify the pm.start_servers
    gsed -i -E "s/^;?\s*pm.start_servers\s*=.*$/;pm.start_servers = $PM_START_SERVERS/" "$CONFIG_ROOT/$FOLDER/php-fpm.d/www.conf"
    # Modify the pm.min_spare_servers
    gsed -i -E "s/^;?\s*pm.min_spare_servers\s*=.*$/;pm.min_spare_servers = $PM_MIN_SPARE_SERVERS/" "$CONFIG_ROOT/$FOLDER/php-fpm.d/www.conf"
    # Modify the pm.max_spare_servers
    gsed -i -E "s/^;?\s*pm.max_spare_servers\s*=.*$/;pm.max_spare_servers = $PM_MAX_SPARE_SERVERS/" "$CONFIG_ROOT/$FOLDER/php-fpm.d/www.conf"
    # Modify the pm.max_requests
    gsed -i -E "s/^;?\s*pm.max_requests\s*=.*$/pm.max_requests = $PM_MAX_REQUESTS/" "$CONFIG_ROOT/$FOLDER/php-fpm.d/www.conf"
  elif [ "$PM" = "dynamic" ]; then
    # Modify the pm.start_servers
    gsed -i -E "s/^;?\s*pm.start_servers\s*=.*$/pm.start_servers = $PM_START_SERVERS/" "$CONFIG_ROOT/$FOLDER/php-fpm.d/www.conf"
    # Modify the pm.min_spare_servers
    gsed -i -E "s/^;?\s*pm.min_spare_servers\s*=.*$/pm.min_spare_servers = $PM_MIN_SPARE_SERVERS/" "$CONFIG_ROOT/$FOLDER/php-fpm.d/www.conf"
    # Modify the pm.max_spare_servers
    gsed -i -E "s/^;?\s*pm.max_spare_servers\s*=.*$/pm.max_spare_servers = $PM_MAX_SPARE_SERVERS/" "$CONFIG_ROOT/$FOLDER/php-fpm.d/www.conf"
    # Modify the pm.max_requests
    gsed -i -E "s/^;?\s*pm.max_requests\s*=.*$/;pm.max_requests = $PM_MAX_REQUESTS/" "$CONFIG_ROOT/$FOLDER/php-fpm.d/www.conf"
  elif [ "$PM" = "ondemand" ]; then
    echo "$PM not implemented yet, consider reviewing the configuration after finishing as it may not be fully configured."
  fi

  # Modify the pm.status_path
  gsed -i -E "s/^;?\s*pm.status_path\s*=.*$/pm.status_path = $PM_STATUS_PATH/" "$CONFIG_ROOT/$FOLDER/php-fpm.d/www.conf"

  # Modify the php_admin_value[error_log]
  PHP_ADMIN_VALUE_ERROR_LOG_PATH="$PHP_ADMIN_VALUE_ERROR_LOG_BASE_PATH\/php-fpm-$MAJOR_VERSION.$MINOR_VERSION.www.log"
  gsed -i -E "s/^;?\s*php_admin_value\[error_log\]\s*=.*$/php_admin_value[error_log] = $PHP_ADMIN_VALUE_ERROR_LOG_PATH/" "$CONFIG_ROOT/$FOLDER/php-fpm.d/www.conf"

  # Message of configuration done
  echo "Version $VERSION done!"

  return 0
}

# Regex pattern to search for phpX.Y
PATTERN='^(php)?[[:space:]]*([0-9]+(\.[0-9]+)*)$'

# Collect matching folder names only (no paths)
PHP_INSTALLED=()
while IFS= read -r DIR_NAME; do
  PHP_INSTALLED+=("$DIR_NAME")
done < <(find "$CONFIG_ROOT" -maxdepth 1 -type d -exec basename {} \; | grep -E "$PATTERN" | sort)
# Added the "All" option
PHP_INSTALLED+=("All")
PHP_INSTALLED+=("Quit")

select OPT in "${PHP_INSTALLED[@]}"; do
  if [ "$OPT" = "Quit" ]; then
    # If option quit, exit without doing anything
    echo "Exiting..."
    exit 0
  elif [ -z "$OPT" ]; then
    # If option not in range, ask again
    echo "Option not available, select one available from above"
    echo "(${#PHP_INSTALLED[@] + 2}) to exit"
  else
    read -rp "WARNING: this script will overwrite all the configurations setup in the php configuration files for (y/N): " CONFIRM
    if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ] || [ "$CONFIRM" = "yes" ] || [ "$CONFIRM" = "YES" ] || [ "$CONFIRM" = "Yes" ]; then
      if [ "$OPT" = "All" ]; then
        echo "Configuring $OPT versions..."
        for ((i=0; i<${#PHP_INSTALLED[@]}-2; i++)); do
          if [[ ${PHP_INSTALLED[i]} =~ php([0-9])([0-9]) ]]; then
            VERSION="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
          else
            VERSION="${PHP_INSTALLED[i]}"
          fi
          FOLDER="${PHP_INSTALLED[i]}"

          configure_version "$VERSION" "$FOLDER"
        done
      else
        if [[ ${PHP_INSTALLED[i]} =~ php([0-9])([0-9]) ]]; then
          VERSION="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
        else
          VERSION="$OPT"
        fi
        FOLDER="$OPT"

        configure_version "$VERSION" "$FOLDER"
      fi
    else
      echo "Exiting without performing any change."
    fi
    exit 0
  fi
done
