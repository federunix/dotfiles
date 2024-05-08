#######################################################
# SPECIAL FUNCTIONS
#######################################################

# Use the best version of pico installed
edit ()
{
  if [ "$(type -t jpico)" = "file" ]; then
    # Use JOE text editor http://joe-editor.sourceforge.net/
    jpico -nonotice -linums -nobackups "$@"
  elif [ "$(type -t nano)" = "file" ]; then
    nano -c "$@"
  elif [ "$(type -t pico)" = "file" ]; then
    pico "$@"
  else
    vim "$@"
  fi
}
sedit ()
{
  if [ "$(type -t jpico)" = "file" ]; then
    # Use JOE text editor http://joe-editor.sourceforge.net/
    sudo jpico -nonotice -linums -nobackups "$@"
  elif [ "$(type -t nano)" = "file" ]; then
    sudo nano -c "$@"
  elif [ "$(type -t pico)" = "file" ]; then
    sudo pico "$@"
  else
    sudo vim "$@"
  fi
}

# Extracts any archive(s) (if unp isn't installed)
extract () {
  for archive in $*; do
    if [ -f $archive ] ; then
      case $archive in
        *.tar.bz2)   tar xvjf $archive    ;;
        *.tar.gz)    tar xvzf $archive    ;;
        *.bz2)       bunzip2 $archive     ;;
        *.rar)       rar x $archive       ;;
        *.gz)        gunzip $archive      ;;
        *.tar)       tar xvf $archive     ;;
        *.tbz2)      tar xvjf $archive    ;;
        *.tgz)       tar xvzf $archive    ;;
        *.zip)       unzip $archive       ;;
        *.Z)         uncompress $archive  ;;
        *.7z)        7z x $archive        ;;
        *)           echo "don't know how to extract '$archive'..." ;;
      esac
    else
      echo "'$archive' is not a valid file!"
    fi
  done
}

# Searches for text in all files in the current folder
ftext ()
{
  # -i case-insensitive
  # -I ignore binary files
  # -H causes filename to be printed
  # -r recursive search
  # -n causes line number to be printed
  # optional: -F treat search term as a literal, not a regular expression
  # optional: -l only print filenames and not the matching lines ex. grep -irl "$1" *
  grep -iIHrn --color=always "$1" . | less -r
}

# Copy file with a progress bar
cpp()
{
  set -e
  strace -q -ewrite cp -- "${1}" "${2}" 2>&1 \
  | awk '{
  count += $NF
  if (count % 10 == 0) {
    percent = count / total_size * 100
    printf "%3d%% [", percent
    for (i=0;i<=percent;i++)
      printf "="
      printf ">"
      for (i=percent;i<100;i++)
        printf " "
        printf "]\r"
      }
    }
  END { print "" }' total_size=$(stat -c '%s' "${1}") count=0
}

# Copy and go to the directory
cpg ()
{
  if [ -d "$2" ];then
    cp $1 $2 && cd $2
  else
    cp $1 $2
  fi
}

# Move and go to the directory
mvg ()
{
  if [ -d "$2" ];then
    mv $1 $2 && cd $2
  else
    mv $1 $2
  fi
}

# Create and go to the directory
mkdirg ()
{
  mkdir -p $1
  cd $1
}

# Goes up a specified number of directories  (i.e. up 4)
up ()
{
  local d=""
  limit=$1
  for ((i=1 ; i <= limit ; i++))
    do
      d=$d/..
    done
  d=$(echo $d | sed 's/^\///')
  if [ -z "$d" ]; then
    d=..
  fi
  cd $d
}

#Automatically do an ls after each cd
# cd ()
# {
#   if [ -n "$1" ]; then
#     builtin cd "$@" && ls
#   else
#     builtin cd ~ && ls
#   fi
# }

# Returns the last 2 fields of the working directory
pwdtail ()
{
  pwd|awk -F/ '{nlast = NF -1;print $nlast"/"$NF}'
}

# Show the current distribution
distribution ()
{
  local dtype
  # Assume unknown
  dtype="unknown"
  
  # First test against Fedora / RHEL / CentOS / generic Redhat derivative
  if [ -r /etc/rc.d/init.d/functions ]; then
    source /etc/rc.d/init.d/functions
    [ zz`type -t passed 2>/dev/null` == "zzfunction" ] && dtype="redhat"
  
  # Then test against SUSE (must be after Redhat,
  # I've seen rc.status on Ubuntu I think? TODO: Recheck that)
  elif [ -r /etc/rc.status ]; then
    source /etc/rc.status
    [ zz`type -t rc_reset 2>/dev/null` == "zzfunction" ] && dtype="suse"
  
  # Then test against Debian, Ubuntu and friends
  elif [ -r /lib/lsb/init-functions ]; then
    source /lib/lsb/init-functions
    [ zz`type -t log_begin_msg 2>/dev/null` == "zzfunction" ] && dtype="debian"
  
  # Then test against Gentoo
  elif [ -r /etc/init.d/functions.sh ]; then
    source /etc/init.d/functions.sh
    [ zz`type -t ebegin 2>/dev/null` == "zzfunction" ] && dtype="gentoo"
  
  # For Mandriva we currently just test if /etc/mandriva-release exists
  # and isn't empty (TODO: Find a better way :)
  elif [ -s /etc/mandriva-release ]; then
    dtype="mandriva"

  # For Slackware we currently just test if /etc/slackware-version exists
  elif [ -s /etc/slackware-version ]; then
    dtype="slackware"

  fi
  echo $dtype
}

# Show the current version of the operating system
ver ()
{
  local dtype
  dtype=$(distribution)

  if [ $dtype == "redhat" ]; then
    if [ -s /etc/redhat-release ]; then
      cat /etc/redhat-release && uname -a
    else
      cat /etc/issue && uname -a
    fi
  elif [ $dtype == "suse" ]; then
    cat /etc/SuSE-release
  elif [ $dtype == "debian" ]; then
    lsb_release -a
    # sudo cat /etc/issue && sudo cat /etc/issue.net && sudo cat /etc/lsb_release && sudo cat /etc/os-release # Linux Mint option 2
  elif [ $dtype == "gentoo" ]; then
    cat /etc/gentoo-release
  elif [ $dtype == "mandriva" ]; then
    cat /etc/mandriva-release
  elif [ $dtype == "slackware" ]; then
    cat /etc/slackware-version
  else
    if [ -s /etc/issue ]; then
      cat /etc/issue
    else
      echo "Error: Unknown distribution"
      exit 1
    fi
  fi
}

# Automatically install the needed support files for this .bashrc file
install_bashrc_support ()
{
  local dtype
  dtype=$(distribution)

  if [ $dtype == "redhat" ]; then
    sudo yum install multitail tree joe
  elif [ $dtype == "suse" ]; then
    sudo zypper install multitail
    sudo zypper install tree
    sudo zypper install joe
  elif [ $dtype == "debian" ]; then
    sudo apt-get install multitail tree joe
  elif [ $dtype == "gentoo" ]; then
    sudo emerge multitail
    sudo emerge tree
    sudo emerge joe
  elif [ $dtype == "mandriva" ]; then
    sudo urpmi multitail
    sudo urpmi tree
    sudo urpmi joe
  elif [ $dtype == "slackware" ]; then
    echo "No install support for Slackware"
  else
    echo "Unknown distribution"
  fi
}

# Show current network information
netinfo ()
{
  echo "--------------- Network Information ---------------"
  /sbin/ifconfig | awk /'inet addr/ {print $2}'
  echo ""
  /sbin/ifconfig | awk /'Bcast/ {print $3}'
  echo ""
  /sbin/ifconfig | awk /'inet addr/ {print $4}'

  /sbin/ifconfig | awk /'HWaddr/ {print $4,$5}'
  echo "---------------------------------------------------"
}

# IP address lookup
alias whatismyip="whatsmyip"
function whatsmyip ()
{
  # Dumps a list of all IP addresses for every device
  # /sbin/ifconfig |grep -B1 "inet addr" |awk '{ if ( $1 == "inet" ) { print $2 } else if ( $2 == "Link" ) { printf "%s:" ,$1 } }' |awk -F: '{ print $1 ": " $3 }';

  # Internal IP Lookup
  echo -n "Internal IP: " ; /sbin/ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'

  # External IP Lookup
  echo -n "External IP: " ; wget http://smart-ip.net/myip -O - -q
}

# View Apache logs
apachelog ()
{
  if [ -f /etc/httpd/conf/httpd.conf ]; then
    cd /var/log/httpd && ls -xAh && multitail --no-repeat -c -s 2 /var/log/httpd/*_log
  else
    cd /var/log/apache2 && ls -xAh && multitail --no-repeat -c -s 2 /var/log/apache2/*.log
  fi
}

# Edit the Apache configuration
apacheconfig ()
{
  if [ -f /etc/httpd/conf/httpd.conf ]; then
    sedit /etc/httpd/conf/httpd.conf
  elif [ -f /etc/apache2/apache2.conf ]; then
    sedit /etc/apache2/apache2.conf
  else
    echo "Error: Apache config file could not be found."
    echo "Searching for possible locations:"
    sudo updatedb && locate httpd.conf && locate apache2.conf
  fi
}

# Edit the PHP configuration file
phpconfig ()
{
  if [ -f /etc/php.ini ]; then
    sedit /etc/php.ini
  elif [ -f /etc/php/php.ini ]; then
    sedit /etc/php/php.ini
  elif [ -f /etc/php5/php.ini ]; then
    sedit /etc/php5/php.ini
  elif [ -f /usr/bin/php5/bin/php.ini ]; then
    sedit /usr/bin/php5/bin/php.ini
  elif [ -f /etc/php5/apache2/php.ini ]; then
    sedit /etc/php5/apache2/php.ini
  else
    echo "Error: php.ini file could not be found."
    echo "Searching for possible locations:"
    sudo updatedb && locate php.ini
  fi
}

# Edit the MySQL configuration file
mysqlconfig ()
{
  if [ -f /etc/my.cnf ]; then
    sedit /etc/my.cnf
  elif [ -f /etc/mysql/my.cnf ]; then
    sedit /etc/mysql/my.cnf
  elif [ -f /usr/local/etc/my.cnf ]; then
    sedit /usr/local/etc/my.cnf
  elif [ -f /usr/bin/mysql/my.cnf ]; then
    sedit /usr/bin/mysql/my.cnf
  elif [ -f ~/my.cnf ]; then
    sedit ~/my.cnf
  elif [ -f ~/.my.cnf ]; then
    sedit ~/.my.cnf
  else
    echo "Error: my.cnf file could not be found."
    echo "Searching for possible locations:"
    sudo updatedb && locate my.cnf
  fi
}

# For some reason, rot13 pops up everywhere
rot13 () {
  if [ $# -eq 0 ]; then
    tr '[a-m][n-z][A-M][N-Z]' '[n-z][a-m][N-Z][A-M]'
  else
    echo $* | tr '[a-m][n-z][A-M][N-Z]' '[n-z][a-m][N-Z][A-M]'
  fi
}

# Trim leading and trailing spaces (for scripts)
trim()
{
  local var=$@
  var="${var#"${var%%[![:space:]]*}"}"  # remove leading whitespace characters
  var="${var%"${var##*[![:space:]]}"}"  # remove trailing whitespace characters
  echo -n "$var"
}

#######################################################
# Set the ultimate amazing command prompt
#######################################################

alias cpu="grep 'cpu ' /proc/stat | awk '{usage=(\$2+\$4)*100/(\$2+\$4+\$5)} END {print usage}' | awk '{printf(\"%.1f\n\", \$1)}'"
function __setprompt
{
  local LAST_COMMAND=$? # Must come first!

  # Define colors
  local LIGHTGRAY="\033[0;37m"
  local WHITE="\033[1;37m"
  local BLACK="\033[0;30m"
  local DARKGRAY="\033[1;30m"
  local RED="\033[0;31m"
  local LIGHTRED="\033[1;31m"
  local GREEN="\033[0;32m"
  local LIGHTGREEN="\033[1;32m"
  local BROWN="\033[0;33m"
  local YELLOW="\033[1;33m"
  local BLUE="\033[0;34m"
  local LIGHTBLUE="\033[1;34m"
  local MAGENTA="\033[0;35m"
  local LIGHTMAGENTA="\033[1;35m"
  local CYAN="\033[0;36m"
  local LIGHTCYAN="\033[1;36m"
  local NOCOLOR="\033[0m"

  # Show error exit code if there is one
  if [[ $LAST_COMMAND != 0 ]]; then
    # PS1="\[${RED}\](\[${LIGHTRED}\]ERROR\[${RED}\])-(\[${LIGHTRED}\]Exit Code \[${WHITE}\]${LAST_COMMAND}\[${RED}\])-(\[${LIGHTRED}\]"
    PS1="\[${DARKGRAY}\](\[${LIGHTRED}\]ERROR\[${DARKGRAY}\])-(\[${RED}\]Exit Code \[${LIGHTRED}\]${LAST_COMMAND}\[${DARKGRAY}\])-(\[${RED}\]"
    if [[ $LAST_COMMAND == 1 ]]; then
      PS1+="General error"
    elif [ $LAST_COMMAND == 2 ]; then
      PS1+="Missing keyword, command, or permission problem"
    elif [ $LAST_COMMAND == 126 ]; then
      PS1+="Permission problem or command is not an executable"
    elif [ $LAST_COMMAND == 127 ]; then
      PS1+="Command not found"
    elif [ $LAST_COMMAND == 128 ]; then
      PS1+="Invalid argument to exit"
    elif [ $LAST_COMMAND == 129 ]; then
      PS1+="Fatal error signal 1"
    elif [ $LAST_COMMAND == 130 ]; then
      PS1+="Script terminated by Control-C"
    elif [ $LAST_COMMAND == 131 ]; then
      PS1+="Fatal error signal 3"
    elif [ $LAST_COMMAND == 132 ]; then
      PS1+="Fatal error signal 4"
    elif [ $LAST_COMMAND == 133 ]; then
      PS1+="Fatal error signal 5"
    elif [ $LAST_COMMAND == 134 ]; then
      PS1+="Fatal error signal 6"
    elif [ $LAST_COMMAND == 135 ]; then
      PS1+="Fatal error signal 7"
    elif [ $LAST_COMMAND == 136 ]; then
      PS1+="Fatal error signal 8"
    elif [ $LAST_COMMAND == 137 ]; then
      PS1+="Fatal error signal 9"
    elif [ $LAST_COMMAND -gt 255 ]; then
      PS1+="Exit status out of range"
    else
      PS1+="Unknown error code"
    fi
    PS1+="\[${DARKGRAY}\])\[${NOCOLOR}\]\n"
  else
    PS1=""
  fi

  # Date
  PS1+="\[${DARKGRAY}\](\[${CYAN}\]\$(date +%a) $(date +%b-'%-m')" # Date
  PS1+="${BLUE} $(date +'%-I':%M:%S%P)\[${DARKGRAY}\])-" # Time

  # CPU
  PS1+="(\[${MAGENTA}\]CPU $(cpu)%"

  # Jobs
  PS1+="\[${DARKGRAY}\]:\[${MAGENTA}\]\j"

  # Network Connections (for a server - comment out for non-server)
  PS1+="\[${DARKGRAY}\]:\[${MAGENTA}\]Net $(awk 'END {print NR}' /proc/net/tcp)"

  PS1+="\[${DARKGRAY}\])-"

  # User and server
  local SSH_IP=`echo $SSH_CLIENT | awk '{ print $1 }'`
  local SSH2_IP=`echo $SSH2_CLIENT | awk '{ print $1 }'`
  if [ $SSH2_IP ] || [ $SSH_IP ] ; then
    PS1+="(\[${RED}\]\u@\h"
  else
    PS1+="(\[${RED}\]\u"
  fi

  # Current directory
  PS1+="\[${DARKGRAY}\]:\[${BROWN}\]\w\[${DARKGRAY}\])-"

  # Total size of files in current directory
  PS1+="(\[${GREEN}\]$(/bin/ls -lah | /bin/grep -m 1 total | /bin/sed 's/total //')\[${DARKGRAY}\]:"

  # Number of files
  PS1+="\[${GREEN}\]\$(/bin/ls -A -1 | /usr/bin/wc -l)\[${DARKGRAY}\])"

  # Skip to the next line
  PS1+="\n"

  if [[ $EUID -ne 0 ]]; then
    PS1+="\[${GREEN}\]>\[${NOCOLOR}\] " # Normal user
  else
    PS1+="\[${RED}\]>\[${NOCOLOR}\] " # Root user
  fi

  # PS2 is used to continue a command using the \ character
  PS2="\[${DARKGRAY}\]>\[${NOCOLOR}\] "

  # PS3 is used to enter a number choice in a script
  PS3='Please enter a number from above list: '

  # PS4 is used for tracing a script in debug mode
  PS4='\[${DARKGRAY}\]+\[${NOCOLOR}\] '
}
PROMPT_COMMAND='__setprompt'

function sshagent_findsockets {
    find /tmp -uid $(id -u) -type s -name agent.\* 2>/dev/null
}

function sshagent_testsocket {
    if [ ! -x "$(which ssh-add)" ] ; then
        echo "ssh-add is not available; agent testing aborted"
        return 1
    fi

    if [ X"$1" != X ] ; then
        export SSH_AUTH_SOCK=$1
    fi

    if [ X"$SSH_AUTH_SOCK" = X ] ; then
        return 2
    fi

    if [ -S $SSH_AUTH_SOCK ] ; then
        ssh-add -l > /dev/null
        if [ $? = 2 ] ; then
            echo "Socket $SSH_AUTH_SOCK is dead!  Deleting!"
            rm -f $SSH_AUTH_SOCK
            return 4
        else
            echo "Found ssh-agent $SSH_AUTH_SOCK"
            return 0
        fi
    else
        echo "$SSH_AUTH_SOCK is not a socket!"
        return 3
    fi
}

function sshagent_init {
    # ssh agent sockets can be attached to a ssh daemon process or an
    # ssh-agent process.

    AGENTFOUND=0

    # Attempt to find and use the ssh-agent in the current environment
    if sshagent_testsocket ; then AGENTFOUND=1 ; fi

    # If there is no agent in the environment, search /tmp for
    # possible agents to reuse before starting a fresh ssh-agent
    # process.
    if [ $AGENTFOUND = 0 ] ; then
        for agentsocket in $(sshagent_findsockets) ; do
            if [ $AGENTFOUND != 0 ] ; then break ; fi
            if sshagent_testsocket $agentsocket ; then AGENTFOUND=1 ; fi
        done
    fi

    # If at this point we still haven't located an agent, it's time to
    # start a new one
    if [ $AGENTFOUND = 0 ] ; then
        eval `ssh-agent`
    fi

    # Clean up
    unset AGENTFOUND
    unset agentsocket

    # Finally, show what keys are currently in the agent
    ssh-add -l
}
