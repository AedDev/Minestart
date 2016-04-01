#!/bin/bash

################################################################################
################################### ABOUT ######################################
################################################################################
#                                                                              #
# Author:      Enrico Ludwig (Morph)                                           #
# Version:     1.2.1.0     (01. April 2016)                                    #
# License:     GNU GPL v2 (See: http://www.gnu.org/licenses/gpl-2.0.txt)       #
# Created:     11. May 2014                                                    #
# Description: Control your Minecraft Server                                   #
#                                                                              #
################################################################################

################################################################################
###                             APPLICATION                                  ###
################################################################################
VERSION="1.2.1.0"
SCRIPT_DIR=$(dirname $0)

# Prints info message to shell
function info {
  echo -e "$COLOR_LGRAY[${COLOR_BLUE}MINESTART${COLOR_LGRAY}][${COLOR_GREEN}INFO${COLOR_LGRAY}] $@$COLOR_DEFAULT"
}

function debug {
  if [[ $DEBUG -eq 1 ]]; then
    echo -e "$COLOR_LGRAY[${COLOR_BLUE}MINESTART${COLOR_LGRAY}][${COLOR_GREEN}DEBUG${COLOR_LGRAY}] $@$COLOR_DEFAULT"
  fi
}

# Prints error message to shell
function error {
  echo -e "$COLOR_LGRAY[${COLOR_BLUE}MINESTART${COLOR_LGRAY}][${COLOR_RED}ERROR${COLOR_LGRAY}] $@$COLOR_DEFAULT"
}

# Prints warning message to shell
function warn {
  echo -e "$COLOR_LGRAY[${COLOR_BLUE}MINESTART${COLOR_LGRAY}][${COLOR_YELLOW}WARN${COLOR_LGRAY}] $@$COLOR_DEFAULT"
}

# Checks, if package 'screen' is installed
#
# Returns: 1 if Package is installed, 0 if not
function isScreenInstalled {
  screen -v &> /dev/null
  if [[ $? -eq 1 ]]; then
    echo 1
    return
  elif [[ $? -eq 127 ]]; then
    echo 0
    return
  else
    echo 0
    return
  fi
}

# Checks if the server is running
#
# Returns: 1 if the server is running or 0 if not
function isRunning {
  local _running=0
  
  # Get PID file
  if [[ -f "${SERVER_JAR}.pid" ]]; then
    # Read PID from file
    PID=$(cat "${SERVER_JAR}.pid")

    # Check PID is alive
    kill -0 $PID &> /dev/null
    ALIVE=$?

    if [[ $ALIVE -eq 0 ]]; then
      _running=1
    else
      # PID file found, but server not running -> remove PID file
      rm "${SERVER_JAR}.pid"
    fi
  fi
  
  echo $_running
}

# This function returns the PID of the screen session $SCREEN_NAME
# (see definition at the top of this file)
#
# Returns: Screen PID
function getScreenPid {
  local SCREEN_PID=$(screen -ls | grep "$SCREEN_NAME" | grep -oEi "([0-9]+)\." | tr -d '.')
  
  echo $SCREEN_PID
}

# Send the given arguments as command to the server
function doCmd {
  if [[ -z $1 ]]; then
    error "There is no command given to execute"
    return
  fi

  if [[ $(isRunning) -eq 1 ]]; then
    screen -S "$SCREEN_NAME" -p 0 -X stuff "$* $(printf \\r)"
  else
    error "There is no Server running with Screen Name '$SCREEN_NAME'"
  fi
}

# Opens the minecraft console (screen session $SCREEN_NAME)
function openConsole {
  if [[ $(isRunning) -eq 1 ]]; then
    screen -r "$SCREEN_NAME"
  else
    error "There is no Server running with Screen Name '$SCREEN_NAME'"
  fi
}

# Starts the minecraft server
function startServer {
  # Check if given JAR file is existing
  if [[ ! -f $SERVER_JAR ]]; then
    error "Could not find Server JAR file '$SERVER_JAR'"
    error "Please set SERVER_JAR constant in $0"
    exit 1
  fi

  local RUNNING=$(isRunning)
  
  if [[ $RUNNING -eq 0 ]]; then
    if [[ $JDK_INSTALLED -eq 1 ]]; then
      screen -S "$SCREEN_NAME" -d -m java -jar -server "-Xms$RAM_MIN" "-Xmx$RAM_MAX" "$SERVER_JAR"

      local ERR_CODE=$?

      if [[ $ERR_CODE -eq 0 ]]; then
        # Save PID
        local PID=$(getScreenPid)
        echo $PID > "$SERVER_JAR.pid"
      
        info "Starting Minecraft Server ..."
        info "Using -server Flag (JDK)"
        info "Using JAR File $SERVER_JAR"
        info "Process ID: $PID"
        info "Server started successfully!"
      else
        error "Could not start Minecraft Server (Error Code: $ERR_CODE)"
        
        # Error Code 127 = Screen is not installed
        if [[ $ERR_CODE -eq 127 ]]; then
          error "You have to install the package 'screen'"
        fi
      fi
    else
      screen -S "$SCREEN_NAME" -d -m java -jar "-Xms$RAM_MIN" "-Xmx$RAM_MAX" "$SERVER_JAR"

      local ERR_CODE=$?

      if [[ $ERR_CODE -eq 0 ]]; then
        # Save PID
        local PID=$(getScreenPid)
        echo $PID > "$SERVER_JAR.pid"

        info "Starting Minecraft Server ..."
        info "Using JAR File $SERVER_JAR"
        info "Process ID: $PID"
        info "Server started successfully!"
      else
        error "Could not start Minecraft Server (Error Code: $ERR_CODE)"
        
        # Error Code 127 = Screen is not installed
        if [[ $ERR_CODE -eq 127 ]]; then
          error "You have to install the package 'screen'"
        fi
      fi
    fi
  else
    warn "The server is still running!"
    warn "You can restart the script using 'restart'"
  fi
}

# Stops the minecraft server
function stopServer {
  info "Stopping Minecraft Server ($SCREEN_NAME)"
  
  if [[ $(isRunning) -eq 0 ]]; then
    warn "Server is NOT running!"
    rm -Rf "${SERVER_JAR}.pid"
    
    return
  fi

  # Send Stop command
  doCmd "stop"

  local TRIES=0 # After 5 tries, error will be thrown
  
  while [[ $(isRunning) -eq 1 ]]; do
    info "Shutting down ..."
    TRIES=$((TRIES+1))

    sleep 1

    if [[ $TRIES -ge 5 ]]; then
        error "Stopping server failed! You should check the server log files"
        
        return
    else
      info "Server shutdown successfull!"
      rm -Rf "${SERVER_JAR}.pid"
      
      return
    fi
  done
}

# Creates a backup of the given world in the following format:
# DD-MM-YYY_hh-mm-ss_$WORLD_NAME.tar.gz
function backupWorld {
  if [[ -z "$1" ]]; then
    error "No world name given"
    return
  fi

  # Check backup folder existing
  if [[ ! -d $WORLD_BACKUP_DIR ]]; then
    mkdir $WORLD_BACKUP_DIR
  fi

  # Build world backup name
  local WORLD_BACKUP_DATE=$(date "+%d-%m-%y_%H-%M-%S")
  local WORLD_BACKUP_FILE="${WORLD_BACKUP_DATE}_${1}.tar.gz"
  local WORLD_BACKUP_FULLPATH="${WORLD_BACKUP_DIR}/${WORLD_BACKUP_FILE}"

  if [[ ! -f "$WORLD_BACKUP_FULLPATH" ]]; then
    info "Creating backup from world $1 ..."
    tar -zcf "$WORLD_BACKUP_FULLPATH" "${BASE_DIR}/$1"

    # Check exit code for success
    if [[ $? -eq 0 ]]; then
      info "Successfully saved world to: $WORLD_BACKUP_FULLPATH"
    else
      error "World backup failed - please check read/write permissions."
    fi
  else
    error "Could not create backup for world '$1': Backup already exists."
  fi
}

function removeWorld {
  if [[ ! -z $1 ]]; then
    if [[ -d $1 ]]; then
      if [[ $BACKUP_REMOVED_WORLDS -eq 1 ]]; then
        if [[ ! -d $WORLD_BACKUP_DIR ]]; then
          mkdir "$WORLD_BACKUP_DIR"
        fi

        backupWorld $1
      else
        info "Removing world $1 ..."

        rm -Rf "$1"
      fi
    else
      error "The world directory $1 is not existing"
    fi
  else
    error "No world name given"
  fi
}

# Opens the minecraft log as stream (tail follow)
function openLog {
  if [[ ! -f $LOG_FILE ]]; then
    error "Logfile $LOG_FILE not found"
    error "If you're using spigot, set logs/latest.log as LOG_FILE"
  else
    tail -f $LOG_FILE
  fi
}

# Prints the help message
function printHelp {
  # Set color to white
  echo -e "$COLOR_LGRAY"
  
  printf "##########################\n"
  printf "### MINESTART v${VERSION} ###\n"
  printf "##########################\n\n"
  
  printf "Developed by Enrico Ludwig (Morph)\n\n"
  
  printf "~$ ./minestart.sh [start|stop|status|restart|reload|console|cmd|log|say|wdel|backup|help] {params}\n\n"
  
  printf "Examples:\n"
  printf "1)  ./minestart.sh start\n"
  printf "2)  ./minestart.sh stop\n"
  printf "3)  ./minestart.sh status\n"
  printf "4)  ./minestart.sh restart\n"
  printf "5)  ./minestart.sh reload\n"
  printf "6)  ./minestart.sh console (Open Minecraft Server console)\n"
  printf "7)  ./minestart.sh cmd [cmdname] {params} (Executes Minecraft Command)\n"
  printf "8)  ./minestart.sh log (Opens the logfile as stream using tail -f)\n"
  printf "9)  ./minestart.sh say [message]\n"
  printf "10) ./minestart.sh whitelist [add|remove|reload] {player}\n"
  printf "11) ./minestart.sh wdel [world_name] (Removes the given world WITH nether and end)\n"
  printf "12) ./minestart.sh backup [world_name] (Creates a backup from given world)\n"
  printf "13) ./minestart.sh help (Shows this help)\n\n"

  printf "Questions? Ideas? Bugs? Contact me here: http://forum.mds-tv.de\n\n"
  
  # Reset color to default
  echo -e "$COLOR_DEFAULT"
  
  exit
}

#####################
### FUNCTIONS END ###
#####################

# Load configuration
if [[ -f "${SCRIPT_DIR}/minestart.cfg" ]]; then
  info "Loading configuration from ${SCRIPT_DIR}/minestart.cfg"
  source "${SCRIPT_DIR}/minestart.cfg"
else
  error "Could not find Minestart configuration file minestart.cfg"
  error "Please create the configuration with all necessary entries"
  error "You can download the default configuration from GitHub:"
  error "https://github.com/morphesus/Minestart"

  # Exit due to config is neccessary!
  return 1
fi

# Check, if first Param is set, or print help if not
if [[ -z $1 ]]; then
  printHelp
fi

# Check if screen is installed!
SCREEN_INSTALLED=$(isScreenInstalled)

if [[ $SCREEN_INSTALLED -eq 0 ]]; then
  error "You have to install the package 'screen'"
  error "On Debian based Systems (like Ubuntu) you can do: 'apt-get install screen'"
  error "On RedHat based Systems (like CentOS) you can do: 'yum install screen'" 
  exit 1
fi

### Commands ###
case "$1" in
  #- General control
  "start")
    startServer
    ;;
  "stop")
    stopServer
    ;;
  "restart")
    stopServer
    startServer
    ;;
  "status")
    if [[ $(isRunning) -eq 1 ]]; then
      info "The Server with screen name '$SCREEN_NAME' is running!"
    else
      info "The Server with screen name '$SCREEN_NAME' is NOT running!"
    fi
    ;;
  "cmd")
    doCmd ${@:2}
    ;;
  "log")
    openLog
    ;;
   "fix-console")
     if [[ $(isRunning) -eq 1 ]]; then
       info "Fixing screen session with PID $(getScreenPid)"
       screen -d "$(getScreenPid).${SCREEN_NAME}"
     fi
     ;;

  #- Execute server internal commands
  "say")
    doCmd "say" ${@:2}
    ;;
  "reload")
    doCmd "reload"
    ;;
  "whitelist")
    doCmd "whitelist" ${@:2}
    ;;

  #- World Management Commands
  "wdel")
    removeWorld $2
    ;;
  "backup")
    backupWorld $2
    ;;

  #- Open the screen session (Minecraft server console)
  "console")
    if [[ $(isRunning) -eq 1 ]]; then
      info "Entering Minecraft Server Console"
      openConsole
      info "Exiting Minecraft Server Console"
    else
      error "The Server with screen name '$SCREEN_NAME' is NOT running!"
    fi
  ;;

  #- Get help
  "help")
    printHelp
    ;;
  *)
    error "Unknown command '$1'"
    ;;
esac