cp /mnt/c/temp/automatic_create_powershell_script_MT5_to_MT4.sh .
SET="default-v2.55-MT5.set"
cp "/mnt/c/temp/$SET" .
bash automatic_create_powershell_script_MT5_to_MT4.sh "$SET" > mt5_to_mt4.ps1
cp mt5_to_mt4.ps1 /mnt/c/temp/
