#!/bin/bash

# Copyright 2011 Popov Igor
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

while true
do
line=""
read line

if [ "${line:0:9}" == "FLAG_DROP" ]; then
        echo "set_zone_radius potato 2"
        STAT_ID=`echo "$line" | awk '{print $2}'` #who drop flag
        echo "$STAT_ID" > player_drop
        echo "0" > count_game_time #unlock; write 0 to indicated starting of counting. if player FLAG_TAKE when count_game_time is le 0.5, scored
	echo "0" > count_hold
fi

if [ "${line:0:9}" == "FLAG_TAKE" ]; then
	COUNT=`cat count_game_time`
	RES=`echo "if(${COUNT}<=0.5)print 0 else 1" | bc`
	if [ "$RES" -eq 0 ]; then #all fine, player take flag right after it was dropped! (in rangoe 0-0.5 seconds) score!
		PLAYER_SCORED=`cat player_drop` #who dropped
		STAT_ID=`echo "$line" | awk '{print $2}'` #who take flag
		if [ "$PLAYER_SCORED" != "$STAT_ID" ]; then #can happend if player take it after he died and dropped, then auto respawned
			echo "CONSOLE_MESSAGE 0xffff00Nice Drop! 0xff4d00$PLAYER_SCORED 0xffff00got 0xff4d001 0xffff00pt!"
			echo "ADD_SCORE_PLAYER ${PLAYER_SCORED} 1"
		fi
	fi
	echo "3" > count_game_time
fi

if [ "${line:0:9}" == "NEW_ROUND" ]; then
        echo "spawn_zone n potato flag 0 62.5 62.5 2 0 0 0 true 15 15 15 2"
fi

if [ "${line:0:9}" == "GAME_TIME" ]; then
	COUNT=`cat count_game_time`
	RES=`echo "if(${COUNT}<=0.5)print 0 else 1" | bc` 
	if [ "$RES" -eq 0 ]; then # block here, not necessery for script to work if it does not do any effect
		GAME_TIME=`echo "$COUNT"`
		GAME_TIME=`echo "$COUNT+0.5" | bc`
		echo "$GAME_TIME" > count_game_time
	elif [ "$COUNT" = "3" ]; then #player took flag, start counting for potato cool down
		HOLD=`cat count_hold`
		HOLD=`echo "${HOLD}+1" | bc`
		echo "$HOLD" > count_hold
		if [ "${HOLD}" = "100" ]; then
			echo "FLAG_HOLD_TIME 1"
			echo "2" > count_game_time
			echo "0" > count_hold
		fi 
	fi
fi

if [ "${line:0:12}" == "FLAG_TIMEOUT" ]; then
	echo "set_zone_radius potato 2"
	echo "FLAG_HOLD_TIME 150"
fi

if [ "${line:0:9}" == "GAME_END" ]; then
	echo "2" > count_game_time
	echo "0" > count_hold
fi

if [ "${line:0:9}" == "NEW_MATCH" ]; then
	echo "2" > count_game_time
	echo "0" > count_hold
fi

done
