#!/bin/bash


home="/home/eightyone81"

audio="$home/scripts/helper/audio"
aur="$home/programs"
background="$home/pictures/backgrounds/current_background"
backup_drive="/mnt/backup_drive"
backup_file="$home/.backup"
record_out="$home/downloads/out.mp4"
srlck="$home/.srlck"
todo_file="$home/documents/todo.txt"

case $1 in
	"help")
		echo "usage: helper [option]"
		echo "options:"
		echo "	help				Print this help."
		echo "	update-aur			Update the AUR programs."
		echo "	install-aur <package>		Install <package> from AUR."
		echo "	remove-aur <package>		Remove <package> from system."
		echo "	background <file>		Set <file> to background in xmonad and lightdm."
		echo "	backup				Backup files specified in $backup_file"
		echo "	open-backup			Mount the backup drive."
		echo "	close-backup			Unmount the backup drive."
		echo "	screenshot			Select a region and save screenshot to clipboard."
		echo "	screenrecord <audiosource>	Select a region and save record to $record_out. Execute again to stop."
		echo "	toggle-mute			Toggle default audio source. With sounds."
		echo "	get-recording			Used for xmobar."
		echo "	get-mute			Used for xmobar"
		echo "	get-volume			Used for xmobar"
		echo "	max-freq			Get max CPU frequency in MHz"
		echo "	cpu-temp			Get CPU temperature in °C"
		echo "	mem-used			Get memory usage in percent"
		echo "	rnd-todo			Get a random TODO from $todo_file"
		echo "	add-todo			Add a TODO to $todo_file"
		echo "	get-spt				Get current spotify song and artist (short)"
		;;

	"update-aur")
		for program in $(ls $aur); do
			cd $aur/$program
			if [ ! "$(git pull)" = "Already up to date." ]; then
				echo "$program needs an update."
			fi
		done
		;;
	
	"install-aur")
		cd $aur
		git clone "https://aur.archlinux.org/$2" && cd $aur/$2
		makepkg -Ccsir

		if [ $? != 0 ]; then
			rm -R $aur/$2
		fi
		;;

	"remove-aur")
		sudo pacman -Rns $2
		rm -R $aur/$2
		;;

	"background")
		rm $background
		ln -s $(realpath $2) $background
		$home/.fehbg
		;;

	"backup")
		sudo mkdir -p $backup_drive
		sudo mount /dev/sdb1 $backup_drive

		rm -Rf $backup_drive/*

		for file in $(cat $backup_file); do
			parent=$(dirname $file)
			mkdir -p $backup_drive$parent
			cp -r $file $backup_drive$parent
		done
		
		sudo umount $backup_drive
		sudo rm -R $backup_drive
		;;

	"open-backup")
		sudo mkdir -p $backup_drive
		sudo mount /dev/sdb1 $backup_drive
		;;

	"close-backup")
		sudo umount $backup_drive
		sudo rm -R $backup_drive
		;;

	"screenshot")
		maim -suq -b 2 | xclip -selection clipboard -t image/png
		;;

	"screenrecord")
		if [ ! -f $srlck ]; then
			if [ "$2" = "-1" ]; then
				src=""
			else
				src="-f pulse -ac 2 -i "$2""
			fi

			slop=$(slop -f "%x %y %w %h %g %i") || exit 1
			read -r X Y W H G ID < <(echo $slop)	
			touch $srlck

			options="-f x11grab -i :0.0+"$X","$Y" $src"
			ffmpeg -y -s "$W"x"$H" -r 30 $options $record_out
		else
			killall ffmpeg	
			rm $srlck
		fi
		;;

	"toggle-mute")
		muted=$(pactl get-source-mute @DEFAULT_SOURCE@)
		pactl set-source-mute @DEFAULT_SOURCE@ toggle

		if [ "$muted" = "Mute: yes" ]; then
			ffplay -autoexit -nodisp $audio/unmute.mp3
		elif [ "$muted" = "Mute: no" ]; then
			ffplay -autoexit -nodisp $audio/mute.mp3
		else
			echo "An error occurred."
		fi
		;;
	
	"get-recording")
		if [ -f $srlck ]; then
			echo "壘"
		else
			echo "雷"
		fi
		;;


	"get-mute")
		muted=$(pactl get-source-mute @DEFAULT_SOURCE@)

		if [ "$muted" = "Mute: yes" ]; then
			echo ""
		elif [ "$muted" = "Mute: no" ]; then
			echo ""
		else
			echo ""
		fi
		;;

	"get-volume")
		volume=$(pactl get-sink-volume @DEFAULT_SINK@ | head -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,')
		echo "$volume"
		;;

	"max-freq")
		awk 'BEGIN {max=-inf} /cpu MHz/ { if ($4 > max) { max = $4 } } END {print int(max)}' /proc/cpuinfo
		;;

	"cpu-temp")
		awk 'NR==1 {print $1/1000}' /sys/class/thermal/thermal_zone*/temp
		;;

	"mem-used")
		awk 'NR == 1{total=$2} NR == 3{free=$2} END {print int((total-free)*100/total)}' /proc/meminfo
		;;

	"rnd-todo")
		shuf -n 1 $todo_file
		;;	

	"add-todo")
		echo "$2" >> $todo_file
		;;

	"get-spt")
		spt_out="$(spt pb -f '%t~%a')"
		if [ $? -eq 0 ]; then
			echo $spt_out | awk -F~ '{split($1, track, "[-(]"); split($2, artist, ","); print track[1]" " "("artist[1]")"}' | tr -s " "
		else
			echo "No song is currently playing."
		fi
		;;
	
	*)
		echo "not valid"
		;;

esac
