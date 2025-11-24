#!/bin/bash
# shellcheck disable=SC2034

# File with variables to set custom variables
## NOTE: all the paths used to be replaced MUST escape the slashes in order to work with the sed command
# PHP.INI

export MEMORY_LIMIT="4G"
export POST_MAX_SIZE="64M"
export UPLOAD_MAX_FILESIZE="64M"

export DATE_TIMEZONE="Europe\/Madrid"

export PDO_MYSQL_DEFAULT_SOCKET="\/private\/tmp\/mysql.sock"
export MYSQLI_DEFAULT_SOCKET="\/private\/tmp\/mysql.sock"

export CURL_CAINFO="\/private\/etc\/ssl\/rootCA.crt"
export OPENSSL_CAFILE="\/private\/etc\/ssl\/rootCA.crt"

# WWW.CONF

export WWW_CONF_USER="username"
export WWW_CONF_GROUP="staff"

export WWW_CONF_LISTEN_SOCKET_BASE_PATH="\/private\/tmp"
#export WWW_CONF_LISTEN_SOCKET_BASE_URI="127.0.0.1:90"
export WWW_CONF_LISTEN_OWNER="$WWW_CONF_USER"
export WWW_CONF_LISTEN_GROUP="$WWW_CONF_GROUP"
export WWW_CONF_LISTEN_MODE="0660"

#export PM="static"
export PM="dynamic"
export PM_MAX_REQUESTS=500

if [ "$PM" = "static" ]; then
  # Static configuration
  export PM_MAX_CHILDREN=20
  export PM_START_SERVERS=2
  export PM_MIN_SPARE_SERVERS=1
  export PM_MAX_SPARE_SERVERS=3
elif [ "$PM" = "dynamic" ]; then
  # Dynamic configuration
  export PM_MAX_CHILDREN=35
  export PM_START_SERVERS=10
  export PM_MIN_SPARE_SERVERS=10
  export PM_MAX_SPARE_SERVERS=17
fi

export PM_STATUS_PATH="\/status"

export PHP_ADMIN_VALUE_ERROR_LOG_BASE_PATH="\/opt\/local\/var\/log\/php"
