#!/bin/bash

#Colores
verde="\e[0;32m\033[1m"
rojo="\e[0;31m\033[1m"
amarillo="\e[0;33m\033[1m"
azul="\e[0;34m\033[1m"
fin="\033[0m\e[0m"

LIST_MEMBERS=true
LIST_ACTIONS=true
MIN_DURATION="00:02:00"
MCOL=8

if [[ -n "$1" ]]; then
    LOG=$1
    [[ ! -f "$LOG" ]] && exit 1
fi

declare -A created_at
declare -A stopped_at
declare -A members
declare -A actions

# ------------------------------------------------------------------------------
# elapsed time
# ------------------------------------------------------------------------------
function elapsed {
    local t0=$(date -u -d "$1" +"%s")
    local t1=$(date -u -d "$2" +"%s")
    echo $(date -u -d "0 $t1 sec - $t0 sec" +"%H:%M:%S")
}

# ------------------------------------------------------------------------------
# list members
# ------------------------------------------------------------------------------
function list-members {
    echo -e "\n${verde}participants: ${fin}"

    i=1
    for m in $msorted; do
        if [[ "$i" == 1 ]]; then
            echo -n "    $m"
            (( i+=1 ))
        elif [[ "$i" == "$MCOL" ]]; then
            echo ", $m"
            i=1
        else
            echo -n ", $m"
            (( i+=1 ))
        fi
    done
    [[ "$i" != "1" ]] && echo || true
}

# ------------------------------------------------------------------------------
# list actions
# ------------------------------------------------------------------------------
function list-actions {
    echo -e "\n${verde}actions: ${fin}"
    while read act; do
        echo "    $act"
    done < <(echo -e "${actions[$_room_]}")
}

# ------------------------------------------------------------------------------
# room created
# ------------------------------------------------------------------------------
function created {
    created_at[$_room_]=$cdatetime
    stopped_at[$_room_]=
    actions[$_room_]="$ctime +++ [$_room_]"
    members[$_room_]=
}

# ------------------------------------------------------------------------------
# room stopped
# ------------------------------------------------------------------------------
function stopped {
    stopped_at[$_room_]=$cdatetime
    actions[$_room_]+="\n$ctime --- [$_room_]"
    duration=$(elapsed "${created_at[$_room_]}" "${stopped_at[$_room_]}")
    [[ "$MIN_DURATION" > "$duration" ]] && return
    msorted=$(echo ${members[$_room_]} | xargs -n1 | sort -u | xargs)

    cat <<EOF

$(echo $_room_ | sed 's/./=/g')
sala: $_room_
$(echo $_room_ | sed 's/./=/g')

created at: ${created_at[$_room_]}

stopped at: ${stopped_at[$_room_]}

duration: $duration
EOF

    [[ "$LIST_MEMBERS" == true ]] && list-members || true
    #[[ "$LIST_ACTIONS" == true ]] && list-actions || true
}

# ------------------------------------------------------------------------------
# main
# ------------------------------------------------------------------------------
while read l; do
    cdatetime=$(echo $l | egrep -o '[0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+:[0-9]+')
    ctime=$(echo $cdatetime | cut -d ' ' -f2)
    _room_=$(echo $l | egrep -o '\[room=[^@]*' | cut -d= -f2)

    if (echo $l | egrep -qs 'Member joined:'); then
        member=$(echo $l | egrep -Eo 'Member joined:.*' | \
                 cut -d':' -f2 | xargs)
        members[$_room_]+="$member "
        actions[$_room_]+="\n$ctime ->  $member"
    elif (echo $l | egrep -qs 'Member left:'); then
        member=$(echo $l | egrep -Eo 'Member left:.*' | \
                 cut -d':' -f2 | xargs)
        members[$_room_]+="$member "
        actions[$_room_]+="\n$ctime  <- $member"
    elif (echo $l | egrep -qs 'Member kicked:'); then
        member=$(echo $l | egrep -Eo 'Member kicked:.*' | \
                 cut -d':' -f2 | xargs)
        members[$_room_]+="$member "
        actions[$_room_]+="\n$ctime  k  $member"
    elif (echo $l | egrep -qs 'Granted owner to .*'); then
        member=$(echo $l | egrep -Eo 'Granted owner to \S*' | \
                 cut -d' ' -f4)
        actions[$_room_]+="\n$ctime  *  $member"
    elif (echo $l | egrep -qs 'Electing new owner:'); then
        chatmember=$(echo $l | egrep -Eo 'ChatMember[^, ]*')
        _room_=$(echo $chatmember | cut -d'[' -f2 | cut -d@ -f1)
        member=$(echo $chatmember | rev | cut -d/ -f1 | rev)
        members[$_room_]+="$member "
        actions[$_room_]+="\n$ctime  *  $member"
    elif (echo $l | egrep -qs 'Created new conference'); then
        created
    elif (echo $l | egrep -qEs 'Stopped\.\s*$'); then
        stopped
    fi
done < <(egrep --line-buffered -s \
             -e 'Member ' \
             -e 'Granted ' \
             -e 'Created ' \
             -e 'Stopped\.' \
             -e 'AutoOwnerRoleManager' \
             $LOG)

echo
echo "==========================================="
echo -e "reporte creado el $(date +'%Y-%m-%d %H:%M:%S')"
echo "==========================================="

# modo de uso:
# cp jicofo-log-analyzer.sh /usr/local/bin/jicofo-log-analyzer
# chmod 755 /usr/local/bin/jicofo-log-analyzer
# jicofo-log-analyzer /var/log/jitsi/jicofo.log > reporte.txt
