#!/bin/bash
#
# Automatically select USB sound devices
# Copyright (C) 2013-2020 Stephen Ostermiller
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA  02110-1301, USA.

# To install:
# Put this script somewhere permanent like /opt/usb-audio-use.sh
# then run:
# sudo /opt/usb-audio-use.sh --install

# To uninstall run:
# sudo /opt/usb-audio-use.sh --uninstall

# The name of any device you want to give priority over other devices
# A case-insensitive substring from your cards will work.  For your
# options run:
#     pacmd list-cards | grep 'name:'
priority="Media_Electronics"

# Volume at which to set the speakers
# (1 to 100000, 20000 is 20%)
# comment this line out not to touch the volume
speakervolume=20000

# Volume at which to set the microphone
# (1 to 100000, 80000 is 80%)
# comment this line out not to touch the volume
micvolume=80000

#####################################################################

install=0
uninstall=0
sleep=0
verbose=0

for i in "$@"
do
    case $i in
        --install)
            install=1
            ;;
        --uninstall)
            uninstall=1
            ;;
        --sleep)
            sleep=1
            ;;
        --verbose)
            verbose=1
            ;;
        *)
            echo "Unknown option $i"
            exit 1
            ;;
    esac
done

if [ $install == 1 ]
then
    if [ $EUID -ne 0 ]
    then
        echo "Error: You are not the root user."
        echo "Run this install as root (or use sudo)"
        exit 1
    fi
    if ! which play > /dev/null
    then
         apt-get -y install sox
    fi
    script=$(readlink -f "$0")
    rulefile=/lib/udev/rules.d/99-usb-audio-auto-select.rules
    if [ -e "$rulefile" ]
    then
        echo "udev rule already exists: $rulefile"
    else
        echo "Creating udev rule: $rulefile"
        echo "ACTION==\"add|remove\", ENV{ID_TYPE}==\"audio\", RUN+=\"$script\"" > "$rulefile"
        udevadm control --reload-rules && udevadm trigger
        echo "Installed udev rule"
    fi
    rulefile=/usr/lib/pm-utils/sleep.d/99usbaudio
    if [ -e "$rulefile" ]
    then
        echo "pm-utils sleep/wake rule already exists: $rulefile"
    else
        echo "Creating pm-utils sleep/wake rule: $rulefile"
        echo -e "#!/bin/sh\n\ncase \"\$1\" in\n'resume' | 'thaw')\n$script\n;;\nesac" > "$rulefile"
        chmod a+x "$rulefile"
        echo "Installed pm-utils sleep/wake rule"
    fi
    exit 0
elif [ $uninstall == 1 ]
then
    if [ $EUID -ne 0 ]
    then
        echo "Error: You are not the root user."
        echo "Run this uninstall as root (or use sudo)"
        exit 1
    fi
    rulefile=/lib/udev/rules.d/99-usb-audio-auto-select.rules
    if [ -e "$rulefile" ]
    then
        echo "Removing udev rule: $rulefile"
        rm -f "$rulefile"
        udevadm control --reload-rules && udevadm trigger
        echo "Removed udev rule"
    else
        echo "udev rule does not exist: $rulefile"
    fi
    rulefile=/usr/lib/pm-utils/sleep.d/99usbaudio
    if [ -e "$rulefile" ]
    then
        echo "Removing pm-utils sleep/wake rule: $rulefile"
        rm -f "$rulefile"
        echo "Removed pm-utils sleep/wake rule"
    else
        echo "pm-utils sleep/wake rule does not exist: $rulefile"
    fi
    exit 0
fi

if [ $sleep == 1 ]
then
    if [ $verbose == 1 ]
    then
        echo "Sleeping 1 second"
    fi
    sleep 1
fi

if [ "$UID" == "0" ]
then
    if [ $verbose == 1 ]
    then
        echo "Checking process table for users running PulseAudio"
    fi
    while read -r user; do
        verbosearg=""
        if [ $verbose == 1 ]
        then
            echo "Forking to run as PulseAudio user: $user"
            verbosearg="--verbose"
        fi
        # tell it to sleep for a second to let pulseaudio install the usb device
        su "$user" -c "bash $0 --sleep $verbosearg" &
    done < <(ps axc -o user,command | grep pulseaudio | cut -f1 -d' ' | sort | uniq)
else
    export PULSE_RUNTIME_PATH="/run/user/$UID/pulse/"
    if pacmd list-cards 2>&1 | grep -q 'No PulseAudio daemon running'
    then
        echo "For user: $(whoami)"
        exit 1
    fi
    # List the sound cards, put USB sound cards first
    cards=$(pacmd list-cards | grep 'name:' | sed -r "s/.*<//g;s/>.*//g;s/.*usb.*/1-\0/gi;s/.*($priority).*/0-\0/gi" | sort | sed -r  's/^([01]-)*//g')
    # The first card
    card=$(echo "$cards" | head -n 1)
    # Find a profile for it, preferrably something with output and input, but fall back to just output
    profile=$(pacmd list-cards | sed -n "/$card/,/^\s*Index:/p" | sed -n '/^\s*profiles:/,/^\s*off/p' | tail -n+2 | grep -v 'available: no' | sed -r 's/^\s+//g;s/: .*//g;s/.*output.*input.*/0-\0/g;s/.*output.*/0-\0/g' | sort | sed -r 's/^(0-)+//g' | head -n 1)
    if [ $verbose == 1 ]
    then
        echo "Enabling: $card $profile"
    fi
    pacmd set-card-profile "$card" "$profile" | grep -vE 'Welcome|>>> $'
    # For each of the other cards
    echo "$cards" | tail -n+2 | while read -r card
    do
        if [ $verbose == 1 ]
        then
            echo "Disabling: $card"
        fi
        pacmd set-card-profile "$card" off | grep -vE 'Welcome|>>> $'
    done

    # List the speakers, put USB speakers first
    speakers=$(pacmd list-sinks | grep 'name:' | sed -r "s/.*<//g;s/>.*//g;s/.*usb.*/1-\0/gi;s/.*($priority).*/0-\0/gi" | sort | sed -r  's/^([01]-)*//g')
    # The first speaker
    speaker=$(echo "$speakers" | head -n 1)
    if [ $verbose == 1 ]
    then
        echo "Setting default speaker: $speaker"
    fi
    pacmd set-default-sink "$speaker" | grep -vE 'Welcome|>>> $'
    if [ $verbose == 1 ]
    then
        echo "Unmuting speaker: $speaker"
    fi
    pacmd set-sink-mute "$speaker" 0 | grep -vE 'Welcome|>>> $'
    if [ -n "$speakervolume" ]
    then
        if [ $verbose == 1 ]
        then
            let volume=$speakervolume/1000
            echo "Setting $volume% volume: $speaker"
        fi
        pacmd set-sink-volume "$speaker" "$speakervolume" | grep -vE 'Welcome|>>> $'
    fi
    # For each of the other speakers
    while read -r speaker; do
        if [ $verbose == 1 ]
        then
            echo "Muting speaker: $speaker"
        fi
        pacmd set-sink-mute "$speaker" 1 | grep -vE 'Welcome|>>> $'
    done < <(echo "$speakers" | tail -n+2)

    mics=$(pacmd list-sources | grep 'name:' | grep input | sed -r "s/.*<//g;s/>.*//g;s/.*usb.*/1-\0/gi;s/.*($priority).*/0-\0/gi" | sort | sed -r  's/^([01]-)*//g')
    # The first mic
    mic=$(echo "$mics" | head -n 1)
    if [ $verbose == 1 ]
    then
        echo "Setting default source: $mic"
    fi
    pacmd set-default-source "$mic" | grep -vE 'Welcome|>>> $'
    if [ $verbose == 1 ]
    then
        echo "Unmuting mic: $mic"
    fi
    pacmd set-source-mute "$mic" 0 | grep -vE 'Welcome|>>> $'
    if [ -n "$micvolume" ]
    then
        if [ $verbose == 1 ]
        then
            let volume=$micvolume/1000
            echo "Setting volume to $volume%: $mic"
        fi
        pacmd set-source-volume "$mic" "$micvolume" | grep -vE 'Welcome|>>> $'
    fi
    # For each of the other mics
    while read -r mic; do
        if [ $verbose == 1 ]
        then
            echo "Muting mic: $mic"
        fi
        pacmd set-source-mute "$mic" 1 | grep -vE 'Welcome|>>> $'
    done < <(echo "$mics" | tail -n+2)

    if [ -e "/usr/lib/libreoffice/share/gallery/sounds/train.wav" ]
    then
        if [ $verbose == 1 ]
        then
            echo "Playing sound: /usr/lib/libreoffice/share/gallery/sounds/train.wav"
        fi
        play "/usr/lib/libreoffice/share/gallery/sounds/train.wav" 2> /dev/null
    else
        echo "Sound file does not exist: /usr/lib/libreoffice/share/gallery/sounds/train.wav"
        exit 1
    fi
fi

exit 0

