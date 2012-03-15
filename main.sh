#!/bin/bash
# script to control RoboRacer LS Duplex under linux

ADMIN=change_to@admin.email.address
DEBUG=1
DEV=`dmesg|awk '/pl2303.*ttyUSB/{print $NF;exit}'|tr -d ' '`
if [ -n "$DEV" ]; then
	DEV=/dev/$DEV
	if [ ! -c $DEV ]; then
		info="pl2303 port does not exist, make sure \
			RoboRacer LS Duplex is connected. If\
			so please reboot it and try again."
		rpr "Problem" "$info"
		exit 1
	fi
fi
# change the following device names if needed, if there
# are no other drives other than the Duplex's then most likely
# the names will be /dev/sr0 and /dev/sr1 
TOPDRIVE=/dev/sr1
BOTTOMDRIVE=/dev/sr2
SCRIPT=${0##*/}

rpr() {
	if [ -n "$ADMIN" ]; then
		echo -e "$2" | mail -s "`hostname -f` \
		RoboRacer: $1" $ADMIN
	fi
}
usage() {
	echo ">>Examples:"
	echo "$SCRIPT demo"
	echo "$SCRIPT load_topdrive"
	echo "$SCRIPT load_bottomdrive"
	echo "$SCRIPT eject_topdrive"
	echo "$SCRIPT retrieve_topdrive"
	echo "$SCRIPT eject_bottomdrive"
	echo "$SCRIPT retrieve_bottomdrive"
	echo "$SCRIPT remove_disc_topdrive"
	echo "$SCRIPT remove_disc_bottomdrive"
	echo "$SCRIPT top_hand_small"
	echo "$SCRIPT top_hand_big"
	echo "$SCRIPT top_hand_back"
	echo "$SCRIPT bottom_hand_small"
	echo "$SCRIPT bottom_hand_big"
	echo "$SCRIPT bottom_hand_back"
	echo "$SCRIPT top_tray_load_disc"
}

w() {
	echo -e "$1" >$DEV
}

ww() {
	case $1 in
		top_hand_small)	w !BNKRG95;;	#top handle turns a small angle
		top_hand_big)	w !BNKRB90;;	#top handle turns a big angle
		top_hand_back)	w !BNKRH96;;	#top handle turns back to origin
		bottom_hand_small)w !BNKPG93;;	#bottom handle turns small angle
		bottom_hand_big) w !BNKPB8E;;	#bottom handle turns a big angle
		bottom_hand_back) w !BNKPH94;;	#bottom handle turns back to origin
		top_tray_load_disc)	w !BNKDP90;;	#release one disc from the top disc loader
		1)	w !BNKLF8E;;
		2)	w !BNKFG89;;
		10)	w !BNKLG8F;;
		13)	w !BNKSTA3;;
		*)
			echo "unsupported parameter" && exit 0
			;;
	esac
	sleep 2
}

eject_topdrive() {
	[ -b $TOPDRIVE ] && /bin/eject $TOPDRIVE || echo "$TOPDRIVE does not exist"
}

retrieve_topdrive() {
	[ -b $TOPDRIVE ] && /bin/eject -t $TOPDRIVE || echo "$TOPDRIVE does not exist"
}

eject_bottomdrive() {
	[ -b $BOTTOMDRIVE ] && /bin/eject $BOTTOMDRIVE || echo "$BOTTOMDRIVE does not exist"
}

retrieve_bottomdrive() {
	[ -b $BOTTOMDRIVE ] && /bin/eject -t $BOTTOMDRIVE || echo "$BOTTOMDRIVE does not exist"
}

load_topdrive() {
	eject_topdrive
	ww top_hand_small
	ww top_hand_back
	ww top_tray_load_disc
	retrieve_topdrive
	[ $DEBUG -eq 1 ] && echo "Top drive $TOPDRIVE is loaded"
}

load_bottomdrive() {
	eject_bottomdrive && sleep 2
	ww bottom_hand_small
	ww bottom_hand_back
	ww top_hand_big
	eject_topdrive && sleep 2
	retrieve_bottomdrive
	ww top_hand_back
	retrieve_topdrive && sleep 2
	[ $DEBUG -eq 1 ] && echo "Bottom drive $BOTTOMDRIVE is loaded"
}
remove_disc_topdrive() {
	ww top_hand_back
	eject_topdrive && sleep 2
	ww top_hand_small
	ww top_hand_back
	retrieve_topdrive
	[ $DEBUG -eq 1 ] && echo "Disc removed from top drive $TOPDRIVE."
}
remove_disc_bottomdrive() {
	ww bottom_hand_back
	eject_bottomdrive && sleep 2
	ww bottom_hand_small
	ww bottom_hand_back
	retrieve_bottomdrive
	[ $DEBUG -eq 1 ] && echo "Disc removed from bottom drive $BOTTOMDRIVE."
}

demo() {
	echo "executing $0 load_topdrive"
	load_topdrive
	echo "Simulating writing data to disc in top drive"
	sleep 5
	echo "executing $0 load_bottomdrive"
	echo "Loading disc from top drive to bottom drive"
	load_bottomdrive
	echo "Simulating labeling disc in bottom drive"
	sleep 5
	echo "executing $0 remove_disc_bottomdrive"
	echo "Removing disc from bottom drive"
	remove_disc_bottomdrive
	echo "Done."
}
if [ -c $DEV -a -b $TOPDRIVE -a -b $BOTTOMDRIVE ]; then
	case $1 in
		demo)
				demo;;
		load_topdrive)
				load_topdrive;;
		load_bottomdrive)
				load_bottomdrive;;
		eject_topdrive)
				eject_topdrive;;
		retrieve_topdrive)
				retrieve_topdrive;;
		eject_bottomdrive)
				eject_bottomdrive;;
		retrieve_bottomdrive)
				retrieve_bottomdrive;;
		remove_disc_bottomdrive)
				remove_disc_bottomdrive;;
		remove_disc_topdrive)
				remove_disc_topdrive;;
		top*|bottom*|1|2|10|13)
				ww $1;;
			*)
				usage;;
	esac
else
	[ $DEBUG -ne 1 ] && rpr "Problem" "Check dud burner's connection"
fi

