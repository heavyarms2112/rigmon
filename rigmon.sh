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
MY_SP_TOKEN="NULL";
acct_email_id=""
acct_password=""
#get a new UUID from website https://www.uuidgenerator.net/version4
#This UUID will represent your Client Term ID (like the one of your Kasa App).
acct_uuid=""

#General timing in seconds
wait_time=600;                 #global wait time
mon_interval=5;                #power monitoring interval time
down_time=480;                 #down time

power_thres=660;               #power consumption threshold value before sending out alert

#Rig specific flags
rig1_name="RIG1";
rig1_curr_wait=0;               #rig wait time
rig1_utime=0;                   #rig timer
rig1_stab='N';                  #rig stabilized
rig1_wait=1;                    #wait flag for rig stabilization
rig1_power=$power_thres;        #power threshold value
rig1_down=0;
rig1_dtime=0;
rig1_curr_dtime=0;

#Rig specific flags
rig2_name="RIG2"
rig2_curr_wait=0;               #rig wait time
rig2_utime=0;                   #rig timer
rig2_wait=1;                    #rig stabilized
rig2_stab='N';                  #wait flag for rig stabilization
rig2_power=$power_thres;        #power threshold value
rig2_down=0;
rig2_dtime=0;
rig2_curr_dtime=0;

#Get the rig device ids using the curl request in new_token function below

#Get a new token to access your smartplug
#curl -s --request POST "https://wap.tplinkcloud.com" --data '{"method": "login","params": {"appType": "Kasa_iOS", "cloudUserName": "'$acct_email_id'", "cloudPassword": "'$acct_password'", "terminalUUID": "'$acct_uuid'" }}' --header "Content-Type: application/json" | grep -o -P 'token.{0,35}' | cut -d'"' -f3

#Use the token generated (from above query) to get the device ids using curl request below and populate rig1_dev_id and rig2_dev_id
#curl -s --request POST "https://wap.tplinkcloud.com?token=YOUR_TOKEN_HERE HTTP/1.1" --data '{"method":"getDeviceList"}' --header "Content-Type: application/json"
rig1_dev_id="";
rig2_dev_id="";

convertsecs() {
 ((h=${1}/3600))
 ((m=(${1}%3600)/60))
 ((s=${1}%60))
 ((d=${1}/86400))
 printf "%02d %02d:%02d:%02d\n" $d $h $m $s
}

new_token(){
    MY_SP_TOKEN=$(curl -s --request POST "https://wap.tplinkcloud.com" \
    --data '{"method": "login","params": {"appType": "Kasa_iOS", "cloudUserName": "'$acct_email_id'", "cloudPassword": "'$acct_password'", "terminalUUID": "'$acct_uuid'" }}' \
    --header "Content-Type: application/json" | grep -o -P 'token.{0,35}' | cut -d'"' -f3
    )
    #echo "New token is $MY_SP_TOKEN";
}

ResetFlags(){
    if [ $1 == "$rig1_name" ];then
        rig1_stab='N';
        rig1_wait=1;
        rig1_utime=0;
        rig1_down=0;
        rig1_curr_dtime=0;
        rig1_dtime=0;
    elif [ $1 == "$rig2_name" ];then
        rig2_stab='N';
        rig2_wait=1;
        rig2_utime=0;
        rig2_down=0;
        rig2_curr_dtime=0;
        rig2_dtime=0;
    else
        echo "Unsupported Reset";
    fi
    #echo " In ResetFlags $(convertsecs $rig1_utime) $(convertsecs $rig2_utime) ";
}

Reboot(){
    #echo " In Reboot "
    if [ $1 == "$rig1_name" ];then
        ResetFlags "$1"
        #power_thres=500;
        Notify "$1" "($rig1_power)"
    elif [ $1 == "$rig2_name" ];then
        ResetFlags "$1"
        Notify "$1" "($rig2_power)"
    else
        echo "Unsupported Reboot";
    fi
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
    #if [ $1 == "$rig1_name" ];then
        if [ "$rig1_curr_dtime" -ge "$down_time" ];then
            printf "Rig $rig1_name is down for $(convertsecs $rig1_curr_dtime). Rebooting...\n" >> "$log_file";
            Reboot "$rig1_name";
        fi;
    #fi;
    #if [ $1 == "$rig2_name" ];then
        if [ "$rig2_curr_dtime" -ge "$down_time" ];then
            printf "Rig $rig2_name is down for $(convertsecs $rig2_curr_dtime). Rebooting...\n" >> "$log_file";
            Reboot "$rig2_name";
        fi;
    #fi;
}

Notify(){
    curr_date_time=`date "+%Y-%m-%d %H:%M:%S"`;
    echo "$curr_date_time power consumption below threshold value: $power_thres Watts; Rebooted Rig: $1 ($2) " >> "$log_file";
    echo "$curr_date_time power consumption below threshold value: $power_thres Watts; Rebooted Rig: $1 ($2)" | mail -s "RigMonitor" "$acct_email_id"
}

GetPower(){
    if [ $# -ne 1 ]; then
        echo "Usage: GetPower <RigName>, eg. GetPower $rig1_name"
    else
        #printf "Running.. $1"
        if [ $1 == "$rig1_name" ]; then
            rig1_power=$(curl -s --request POST "https://wap.tplinkcloud.com/?token=$MY_SP_TOKEN HTTP/1.1" \
            --data '{"method":"passthrough", "params": {"deviceId": "'$rig1_dev_id'", "requestData": "{\"system\":{\"get_sysinfo\":null},\"emeter\":{\"get_realtime\":null}}" }}' \
            --header "Content-Type: application/json" | grep -o -P 'power.{0,10}' | cut -d':' -f2
            )
        elif [ $1 == "$rig2_name" ]; then
            rig2_power=$(curl -s --request POST "https://wap.tplinkcloud.com/?token=$MY_SP_TOKEN HTTP/1.1" \
            --data '{"method":"passthrough", "params": {"deviceId": "'$rig2_dev_id'", "requestData": "{\"system\":{\"get_sysinfo\":null},\"emeter\":{\"get_realtime\":null}}" }}' \
            --header "Content-Type: application/json" | grep -o -P 'power.{0,10}' | cut -d':' -f2
            )
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
     echo -e "[$curr_date_time] DownTime threshold: $down_time Waittime threshold: $wait_time";
     echo -e "R1: $rig1_name($rig1_stab) $rig1_power Watts, U: $(convertsecs $rig1_utime), D: $(convertsecs $rig1_curr_dtime), W: $(convertsecs $rig1_curr_wait)";
     echo -e "R2: $rig2_name($rig2_stab) $rig2_power Watts, U: $(convertsecs $rig2_utime), D: $(convertsecs $rig2_curr_dtime), W: $(convertsecs $rig2_curr_wait)";
 }

printStuff(){
    printf "\033c" #clear screen
    echo -e "${BYel}"
    echo -e "------------------------------------------------------------------------"
    echo -e "|   RIGMON v1.0 : Auto reboot rigs based on power consumption values   |"
    echo -e "------------------------------------------------------------------------""${RCol} "
    #echo "power consumption with interval $mon_interval secs after wait time of $wait_time secs";
    curr_date_time=`date "+%Y-%m-%d %H:%M:%S"`;
    echo -e " screen refresh interval: $mon_interval sec, power consumption threshold: $power_thres Watts";
    echo -e "------------------------------------------------------------------------";
}
 printStuff;
log_file=`date "+%Y-%m-%d.log"`;
new_token;
while true
do
    GetPower "$rig1_name"
    GetPower "$rig2_name"
    printStuff;
    printTime;
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
            CheckDownTime
        fi
    fi
    if [ $rig2_wait == 0 ];then
        GetPower "$rig2_name";
        if (( $(echo "$rig2_power < $power_thres" | bc -l) )); then
            rig2_dtime=$((rig2_dtime+mon_interval));
            rig2_down=1;
            CheckDownTime
        fi
    fi
done
