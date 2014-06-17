#!/bin/bash

##########################################################################
################################ ABOUT ###################################
##########################################################################
#                                                                        #
# Author:      Enrico Ludwig (Morph)                                     #
# Version:     1.1.1.0 (12. May 2014)                                    #
# License:     GNU GPL v2 (See: http://www.gnu.org/licenses/gpl-2.0.txt) #
# Created:     11. May 2014                                              #
# Description: Control your Minecraft Server                             #
#                                                                        #
##########################################################################

########################
### GENERAL SETTINGS ###
########################

SERVER_JAR="server.jar"

RAM_MIN="1G" # M = Megabytes, G = Gigabytes
RAM_MAX="4G" # M = Megabytes, G = Gigabytes

SCREEN_NAME="MyServer"

JDK_INSTALLED=0 # Set to 1, if you're using the JDK instead of JRE on your server

###################
### APPLICATION ###
###################
VERSION="1.1.1.0"

###################
### COLOR CODES ###
###################
COLOR_DEFAULT="\e[39m"
COLOR_LGRAY="\e[37m"
COLOR_RED="\e[31m"
COLOR_YELLOW="\e[33m"
COLOR_GREEN="\e[32m"
COLOR_BLUE="\e[94m"

#################
### FUNCTIONS ###
#################

# Prints info message to shell
function info {
  echo -e "$COLOR_LGRAY[${COLOR_BLUE}MINESTART${COLOR_LGRAY}][${COLOR_GREEN}INFO${COLOR_LGRAY}] $@$COLOR_DEFAULT"
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
# 1 = Package is installed
# 2 = Package is NOT installed
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

# 1 = Server is running
# 0 = Server is not running
function isRunning {
  # At first, check if there is already a screen session
  $(screen -ls | grep -q "$SCREEN_NAME")
  
  if [[ $? -eq 0 ]]; then
    echo 1
  else
    echo 0
  fi
}

# This function returns the PID of the screen session $SCREEN_NAME
# (see definition at the top of this file)
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
    rm -Rf "$SERVER_JAR.pid"
    
    return
  else
    doCmd "stop"
  fi
  
  local TRIES=0 # After 5 tries, error will be thrown
  while sleep 1
    info "Shutting down ..."
    TRIES=$((TRIES+1))
    
    if [[ $TRIES -ge 5 ]]; then
      # Check running again and give feedback
      if [[ $(isRunning) -eq 1 ]]; then
        error "Stopping server failed! You should check the server log files"
        return
      else
        info "Server was stopped successfully!"
        return
      fi
      
      return
    fi
  do
    # Only if the server is offline, remove the PID file
    if [[ $(isRunning) -eq 0 ]]; then
      rm -Rf "$SERVER_JAR.pid"
    fi
  done
}

# Prints the help message
function printHelp {
  # Set color to white
  echo -e "$COLOR_LGRAY"
  
  printf "##########################\n"
  printf "### MINESTART v${VERSION} ###\n"
  printf "##########################\n\n"
  
  printf "Developed by Enrico Ludwig (Morph)\n\n"
  
  printf "~$ minestart [start|stop|restart|reload|help|status|(minecraft command)] [(minecraft params)]\n\n"
  
  printf "Examples:\n"
  printf "1. ./minestart.sh start (Starts the server from the current directory)\n"
  printf "2. ./minestart.sh stop (Stopps the server from the current directory)\n"
  printf "3. ./minestart.sh status (Prints the server status (online / offline))\n"
  printf "4. ./minestart.sh restart (Restarts the server from the current directory)\n"
  printf "5. ./minestart.sh reload (Reloads the server (alias for 'cmd reload')\n"
  printf "6. ./minestart.sh console (Opens the screen session with the minecraft server console)\n"
  printf "7. ./minestart.sh cmd [cmdname] {params} (Executes the given Minecraft Command with optional arguments)\n"
  printf "8. ./minestart.sh help (Shows this help)\n\n"

  printf "Questions? Ideas? Bugs? Contact me here: http://forum.mds-tv.de\n\n"
  
  # Reset color to default
  echo -e "$COLOR_DEFAULT"
  
  exit
}

#####################
### FUNCTIONS END ###
#####################

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

  #- Execute server internal commands
  "cmd")
    doCmd ${@:2}
    ;;
  "reload")
    doCmd "reload"
    ;;
  "say")
    doCmd "say" ${@:2}

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
