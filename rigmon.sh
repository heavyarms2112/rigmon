RCol='\e[0m' # Text Reset
# Regular           Bold                Underline           High Intensity      BoldHigh Intens     Background          High Intensity Backgrounds
Bla='\e[0;30m';     BBla='\e[1;30m';    UBla='\e[4;30m';    IBla='\e[0;90m';    BIBla='\e[1;90m';   On_Bla='\e[40m';    On_IBla='\e[0;100m';
Red='\e[0;31m';     BRed='\e[1;31m';    URed='\e[4;31m';    IRed='\e[0;91m';    BIRed='\e[1;91m';   On_Red='\e[41m';    On_IRed='\e[0;101m';
Gre='\e[0;32m';     BGre='\e[1;32m';    UGre='\e[4;32m';    IGre='\e[0;92m';    BIGre='\e[1;92m';   On_Gre='\e[42m';    On_IGre='\e[0;102m';
Yel='\e[0;33m';     BYel='\e[1;33m';    UYel='\e[4;33m';    IYel='\e[0;93m';    BIYel='\e[1;93m';   On_Yel='\e[43m';    On_IYel='\e[0;103m';
Blu='\e[0;34m';     BBlu='\e[1;34m';    UBlu='\e[4;34m';    IBlu='\e[0;94m';    BIBlu='\e[1;94m';   On_Blu='\e[44m';    On_IBlu='\e[0;104m';
Pur='\e[0;35m';     BPur='\e[1;35m';    UPur='\e[4;35m';    IPur='\e[0;95m';    BIPur='\e[1;95m';   On_Pur='\e[45m';    On_IPur='\e[0;105m';
Cya='\e[0;36m';     BCya='\e[1;36m';    UCya='\e[4;36m';    ICya='\e[0;96m';    BICya='\e[1;96m';   On_Cya='\e[46m';    On_ICya='\e[0;106m';
Whi='\e[0;37m';     BWhi='\e[1;37m';    UWhi='\e[4;37m';    IWhi='\e[0;97m';    BIWhi='\e[1;97m';   On_Whi='\e[47m';    On_IWhi='\e[0;107m';


#HS110 smart plug specific
MY_SP_TOKEN="<replace-token>";
rig1_dev_id="<dev_id1>";
rig2_dev_id="<dev_id2>";

#Test variables
#TEST_DUR=600; 

#General
wait_time=60;                  #global wait time 
mon_interval=5;                #power monitoring interval time
down_time=40;
power_thres=1250;               #power consumption threshold value
print_interval=0;

#Rig specific
rig1_name="top";
rig1_curr_wait=0;               #rig wait time
rig1_utime=0;                   #rig timer
rig1_stab='N';                  #rig stabilized
rig1_wait=1;                    #wait flag for rig stabilization
rig1_power=$power_thres;        #power threshold value
rig1_down=0;
rig1_dtime=0;
rig1_curr_dtime=0;


#Rig specific
rig2_name="bot"
rig2_curr_wait=0;               #rig wait time
rig2_utime=0;                   #rig timer
rig2_wait=1;                    #rig stabilized
rig2_stab='N';                  #wait flag for rig stabilization
rig2_power=$power_thres;        #power threshold value
rig2_down=0;
rig2_dtime=0;
rig2_curr_dtime=0;


convertsecs() {
 ((h=${1}/3600))
 ((m=(${1}%3600)/60))
 ((s=${1}%60))
 ((d=${1}/86400))
 printf "day:%02d %02d:%02d:%02d\n" $d $h $m $s
}

ResetFlags(){
    if [ $1 == "$rig1_name" ];then
        rig1_stab='N';
        #rig1_pwrcycle=1;
        rig1_wait=1;
        rig1_utime=0;
        rig1_down=0;
        rig1_curr_dtime=0;
        rig1_dtime=0;        
    fi    
    if [ $1 == "bot" ];then
        rig2_stab='N';
        #rig2_pwrcycle=1;
        rig2_wait=1;
        rig2_utime=0;
        rig2_down=0;
        rig2_curr_dtime=0;
        rig2_dtime=0;        
    fi
    #echo " In ResetFlags $(convertsecs $rig1_utime) $(convertsecs $rig2_utime) ";
}

CheckDownTime(){
    if [ $rig1_down == 1 ]; then
        rig1_curr_dtime=$rig1_dtime;
    fi
    if [ $rig2_down == 1 ]; then
        rig2_curr_dtime=$rig2_dtime;
    fi

    curr_date_time=`date "+%Y-%m-%d %H:%M:%S"`;
    echo "$curr_date_time Current downtime : $(convertsecs $rig1_curr_dtime) $(convertsecs $rig2_curr_dtime)";
    if [ $1 == "$rig1_name" ];then
        if [ "$rig1_curr_dtime" -ge "$down_time" ];then
            echo "Rig $1 is down for $(convertsecs $rig1_curr_dtime). Rebooting..." >> "$log_file";
            Reboot "$1";
        fi;
    fi;
    if [ $1 == "bot" ];then        
        if [ "$rig2_curr_dtime" -ge "$down_time" ];then
            echo "Rig $1 is down for $(convertsecs $rig2_curr_dtime). Rebooting..." >> "$log_file";            
            Reboot "$1";
        fi;
    fi;    
}

Reboot(){
    #echo " In Reboot "
    if [ $1 == "$rig1_name" ];then
        ResetFlags "$1"
        Notify "$1" "($rig1_power)"
    fi
    if [ $1 == "bot" ];then
        ResetFlags "$2"
        Notify "$1" "($rig2_power)"
    fi
}

Notify(){
    curr_date_time=`date "+%Y-%m-%d %H:%M:%S"`;
    echo "$curr_date_time power consumption below threshold value: $power_thres Watts; Rebooted Rig: $1 ($2) " >> "$log_file";
    echo "$curr_date_time power consumption below threshold value: $power_thres Watts; Rebooted Rig: $1 ($2)" | mail -s "RigMonitor" <email_id>                                                                                                                              
}

GetPower(){
    if [ $# -ne 1 ]; then
        echo "Usage: GetPower <RigName>, eg. GetPower $rig1_name"
    else
        #printf "Running.."
        if [ "$1" == "$rig1_name" ]; then
            for ((i = 1; i <= 1; i++)); do
                rig1_power=$(curl -s --request POST "https://wap.tplinkcloud.com/?token=$MY_SP_TOKEN HTTP/1.1" \
                --data '{"method":"passthrough", "params": {"deviceId": "'$rig1_dev_id'", "requestData": "{\"system\":{\"get_sysinfo\":null},\"emeter\":{\"get_realtime\":null}}" }}' \
                --header "Content-Type: application/json" | grep -o -P 'power.{0,10}' | cut -d':' -f2 
                )
            done 
        elif [ "$1" == "bot" ]; then
            for ((i = 1; i <= 1; i++)); do
                rig2_power=$(curl -s --request POST "https://wap.tplinkcloud.com/?token=$MY_SP_TOKEN HTTP/1.1" \
                --data '{"method":"passthrough", "params": {"deviceId": "'$rig2_dev_id'", "requestData": "{\"system\":{\"get_sysinfo\":null},\"emeter\":{\"get_realtime\":null}}" }}' \
                --header "Content-Type: application/json" | grep -o -P 'power.{0,10}' | cut -d':' -f2
                )
            done
        else
            echo "Rig Name: $1 is not supported";
        fi
    fi  
}

CheckWait(){
    rig1_curr_wait=$((rig1_curr_wait+mon_interval));
    rig2_curr_wait=$((rig2_curr_wait+mon_interval));
    #curr_date_time=`date "+%Y-%m-%d %H:%M:%S"`;
    if [ $rig1_stab == 'Y' ];then
        rig1_curr_wait=0;
    fi;
    if [ $rig2_stab == 'Y' ];then
        rig2_curr_wait=0;
    fi;       
    #echo "$curr_date_time Current waittime : $(convertsecs $rig1_curr_wait) $(convertsecs $rig2_curr_wait)";
    if [ $rig1_stab == 'N' ] && [ "$rig1_curr_wait" -ge "$wait_time" ];then
        rig1_curr_wait=0;
        rig1_wait=0;
        rig1_stab='Y';     
    fi
    if [ $rig2_stab == 'N' ] && [ "$rig2_curr_wait" -ge "$wait_time" ];then
        rig2_curr_wait=0;
        rig2_wait=0;
        rig2_stab='Y';
    fi 
    #echo -e "$curr_date_time Power-consumption: $rig1_name,$rig1_power ($rig1_stab) | $rig2_name,$rig2_power ($rig2_stab)";       
        
}

countUpTime(){
    if [ $rig1_down == 0 ];then
        rig1_utime=$((rig1_utime+mon_interval));
    fi;
    if [ $rig2_down == 0 ];then
        rig2_utime=$((rig2_utime+mon_interval));
    fi;
}

printTime(){
    curr_date_time=`date "+%Y-%m-%d %H:%M:%S"`;                                
    echo -e "$curr_date_time Power-consumption: $rig1_power Watts   | $rig2_power Watts";
    echo -e "$curr_date_time Current uptime   : $(convertsecs $rig1_utime) | $(convertsecs $rig2_utime)";    
    echo -e "$curr_date_time Current downtime : $(convertsecs $rig1_curr_dtime) | $(convertsecs $rig2_curr_dtime)";
    if [ $rig1_wait == 1 ] || [ $rig2_wait == 1 ];then
    echo -e "$curr_date_time Current waittime : $(convertsecs $rig1_curr_wait) | $(convertsecs $rig2_curr_wait)";
    fi;
}

printStuff(){
    printf "\033c" #clear screen
    echo -e "${Blu}"
    echo -e "------------------------------------------------------------------------"
    echo -e "    RIGMON v1.0 : Auto reboot rigs based on power consumption values    "
    echo -e "------------------------------------------------------------------------"
    echo -e "${RCol} "
    #echo "power consumption with interval $mon_interval secs after wait time of $wait_time secs";
    curr_date_time=`date "+%Y-%m-%d %H:%M:%S"`;
    echo -e "Screen refreshes every $mon_interval seconds";
    echo -e "------------------------------------------------------------------------";
    echo -e "                                       Rig1 - $rig1_name($rig1_stab)   | Rig2 - $rig2_name($rig2_stab)";
}

printStuff;
log_file=`date "+%Y-%m-%d.log"`;
#log_file+=".log";
#echo "curr_date_time: Logging starts" >> "$log_file";
while true
do 
    #CLEAR_CYCLE=$((TEST_DUR-mon_interval))
    print_interval=$(($print_interval+1));
    #if [ $print_interval -ge 10 ];then
    #    print_interval=0;
        GetPower "$rig1_name"
        GetPower "$rig2_name"
        printStuff;
        printTime;
    #fi;
    sleep $mon_interval
    countUpTime;
    if [ $rig1_wait == 1 ] || [ $rig2_wait == 1 ]; then
        CheckWait
    fi

    if [ $rig1_wait == 0 ];then
        GetPower "$rig1_name"
        if (( $(echo "$rig1_power < $power_thres" | bc -l) )); then
            rig1_dtime=$((rig1_dtime+mon_interval));
            rig1_down=1;
            CheckDownTime "$rig1_name"            
        fi
    fi
    if [ $rig2_wait == 0 ];then
        GetPower "bot";
        if (( $(echo "$rig2_power < $power_thres" | bc -l) )); then
            rig2_dtime=$((rig2_dtime+mon_interval));  
            rig2_down=1;        
            CheckDownTime "$rig2_name"            
        fi
    fi
done
