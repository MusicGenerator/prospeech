#!/bin/bash --login

### Uncomment the next line if you get problems with special characters.
### Also make sure that the locale it is activated in /etc/locale.gen
#export LANG="en_US.UTF-8"

MANAGE_SCRIPT_SETTINGS_FILE="$HOME/src/manage.conf"

# Read settings for this script
if [ -f "${MANAGE_SCRIPT_SETTINGS_FILE}" ]; then
  source "${MANAGE_SCRIPT_SETTINGS_FILE}"
else
  # Start only bot1 as fallback if manage.conf does not exist.
  BOTS_ENABLED="1"
fi

function show_help() {
    cat<<EOF
USAGE
  ${0} [OPTIONS]

OPTIONS
  stop                        Stop the bot(s)
  start                       Start the bot(s)
  restart                     Restart the bot(s)
  log                         Show the bots log using tail
  status                      Show if bots are running or not
  -h|--help                   Show this help
EOF
}

function start_bot_ruby() {
  local botid=${1}
  source ~/.rvm/scripts/rvm
  rvm use @bots

  ### We need to be in this directory in order to start the bot(s).
  cd $HOME/src/prospeech/core

  ### Export enviroment variable for tmux
  export HOME=$HOME
  tmux new-session -d -s "bot${botid}" "while true; do LD_LIBRARY_PATH=$HOME/src/celt/lib/ ruby $HOME/src/prospeech/core/pluginbot.rb --config=$HOME/src/bot${botid}_conf.yml >> $HOME/logs/bot${botid}.log 2>&1 ; sleep 10; done"
}

function stop_bot_ruby() {
  local botid=${1}
  tmux kill-session -t "bot${botid}" > /dev/null 2>&1
}

function start_bot_mpd() {
  local botid=${1}
  mpd $HOME/mpd${botid}/mpd.conf > /dev/null 2>&1
}

function start_all_bots() {
  for botid in ${BOTS_ENABLED};
  do
    start_bot_ruby ${botid}
  done
}

function stop_all_bots() {
  for botid in ${BOTS_ENABLED};
  do
    stop_bot_ruby ${botid}
  done
}

function restart_all_bots() {
  stop_all_bots
  start_all_bots
}

function status_bot() {
  local botid=${1}
  local _status=$(tmux list-sessions 2> /dev/null | sed -r -n -e "s/^(bot)${botid}.*/\1/p")

  if [ "${_status}" == "bot" ]; then
    echo "Bot ${botid} is running"
  else
    echo "Bot ${botid} is not running"
  fi
}

function status_all_bots() {
  for botid in ${BOTS_ENABLED};
  do
    status_bot ${botid}
  done
}

show_disclaimer() {
  cat <<EOF

  Your bot(s) should now be connected to the configured Mumble server.

  _START AS APPROPRIATE USER_
    Make sure to run this script as user 
    DO NOT RUN THIS SCRIPT AS root.
    Some documentation fit also here can be found at 
    http://mumble-ruby-pluginbot.readthedocs.io/

  _BUGS/WISHES/IDEAS_
    If you think you found a bug, have a wish for the bot or some ideas please don't
    hesitate to create an issue at https://github.com/MusicGenerator/prospeech/issues

  Have fun with the prospeech

EOF
}

function log() {
  TAIL_BIN="$(which tail)"
  echo -en "\n\nPress Ctrl+c to quit.\n"
  echo "Showing" ~/logs/*.log
  echo
  "${TAIL_BIN}" -f -n10 ~/logs/*.log
}

function parse() {
  if [ "$#" -le "0" ]; then
    show_help
  fi

  while [ "$#" -gt "0" ]; do
    case ${1} in
       status)
           status_all_bots
           #exit $?
           shift
           ;;
       start)
           restart_all_bots
           show_disclaimer
           shift
           ;;
       restart)
           restart_all_bots
           show_disclaimer
           shift
           ;;
       stop)
           stop_all_bots
           shift
           ;;
       -h|--help)
           show_help
           shift
           ;;
       log)
           log
           shift
           ;;
       *)
          show_help
          shift
          ;;
      esac
    done
}

parse "$@"
