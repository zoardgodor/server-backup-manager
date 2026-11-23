#!/usr/bin/env fish
clear
set dir (dirname (realpath (status --current-filename)))
set conf "$dir/config.json"

if not test -f "$conf"
echo "Creating config.json..."
printf '{\n    "destination": "",\n    "sources": [],\n    "compression_level": 5,\n    "keepbackups": 2,\n    "interval_hours": 2,\n    "setup": false\n}\n' > "$conf"
echo "Please read the README.md before you use this script."
echo "Run --setup to set up your config.json file."
exit
end

if not type -q jq
    echo "jq is not installed. Please install jq to continue."
    echo "Do you want to install it now? (Only works on Debian-based systems) [y/n]"
    read -P "Install jq? " jqyn
    if test "$jqyn" = "y"
        sudo apt update && sudo apt install jq -y
        if not type -q jq
        echo "Installation failed."
        exit
        end
    else
        exit
    end
end

function setup
echo "Where do you want to store your backups? (e.g. /mnt/backups)"
read -P "Destination: " des
if test -z "$des"
    echo "Destination cannot be empty. Please enter a valid destination directory."
    exit
end
if not test -d "$des"
echo "Destination directory does not exist. Do you want to create it? [y/n]"
read -P "Create directory? " dircyn
if test "$dircyn" = "y"
mkdir -p "$des"
else
echo "Please enter a valid destination directory."
exit
end
end
echo "What compression level do you want to use? (1-9, 1=fastest, 9=best)"
read -P "Compression Level: " comp
if not test "$comp" -ge 1 -a "$comp" -le 9
echo "Compression level must be between 1 and 9."
exit
end
echo "How many backups do you want to keep? (e.g. 5)"
read -P "Keep Backups: " keep
if not test "$keep" -ge 1
echo "Keep backups must be at least 1."
exit
end
echo "How often do you want to run the backup? (in hours, e.g. 24)"
read -P "Interval (hours): " interval
if not string match -rq '^[0-9]+([.,][0-9]+)?$' "$interval"
    echo "Please enter a valid number (e.g. 0.5, 1, 2, 1.5)"
    exit
end
set interval (string replace -r ',' '.' -- "$interval")
if test "$interval" -le 0
    echo "Interval must be greater than 0."
    exit
end
# if not test "$interval" -ge 1
# echo "Interval must be at least 1 hour."
# exit
# end
echo "What sources do you want to backup? (e.g. /home/user/Server/ /home/user/Documents/)"
echo "Enter each source on a new line. Type 'done' when finished."
set sources
while true
    read -P "Source: " source
    if test "$source" = "done"
    break
    end
    if not test -d "$source"
    echo "Source directory does not exist. Select a valid directory."
    continue
    end
    set -a sources $source
end
if test -f "$conf"
    jq -n \
        --arg destination "$des" \
        --argjson compression_level "$comp" \
        --argjson keepbackups "$keep" \
        --argjson interval_hours "$interval" \
        --argjson setup true \
        --args \
        '{destination: $destination, compression_level: $compression_level, keepbackups: $keepbackups, interval_hours: $interval_hours, sources: $ARGS.positional, setup: $setup}' $sources > "$conf"
else
    echo "Error: config.json file not found."
    exit
end  
  
end
if test "$argv[1]" = "--setup"
    setup
    exit
end
set desti (jq -r '.destination' "$conf")
set compl (jq -r '.compression_level' "$conf")
set keep (jq -r '.keepbackups' "$conf")
set interval (jq -r '.interval_hours' "$conf")
set sources (jq -r '.sources[]' "$conf")
set setup (jq -r '.setup' "$conf")
if test "$setup" = "false"
    echo "Please run the script with --setup to configure your config.json file."
    exit
end

function restore
    set backups99 (ls -1t "$desti"/*.tar.gz 2>/dev/null)
    if test (count $backups99) -eq 0
        echo "No backups found in $desti"
        exit
    end
    echo "Available backups:"
    for backup99 in $backups99
        echo "    $backup99"
    end
    read -P "Enter the backup file you want to restore (e.g. 2026-01-01_01-00-00.tar.gz): " restorefile
    set restore "$desti/$restorefile"
    if test -f "$restore"
        read -P "Are you sure you want to restore this backup? This will overwrite exsisting files. (A backup will be created before restoring) [y/n]: " confirm
        if test "$confirm" != "y"
        echo "Cancelled."
        exit
        end
        echo "Creating a backup before restoring..."
        set timename (date "+%Y-%m-%d_%H-%M-%S")
        echo "Backing up to $desti/$timename"
        if tar -cf "$desti/$timename.tar.gz" --use-compress-program="gzip -$compl" -- $sources
        echo "Backup completed successfully."
        else
        echo "Backup failed!!!!!!!!!!!!!!!!!!!!!"
        echo " try running the script with --setup to reconfigure your config.json file."
        exit
        end
        read -P "Press enter to continue"
        echo "Restoring backup $restore..."
        if tar -xf "$restore" -C /
        echo "Restore completed successfully."
        else
        echo "Restore failed!"
        exit
        end
        echo "Removing old backups..."
        set backups (ls -1t "$desti"/*.tar.gz 2>/dev/null)
        if test (count $backups) -gt $keep
            set old $backups[(math "$keep+1")..-1]
            if contains -- "$restore" $old
                echo "The backup you are restored is also the oldest backup. It will be removed. Do you want to save it somewhere else, before removing it from there? [y/n]"
                read -P "Save backup? " save
                if test "$save" = "y"
                    set savepath "$HOME"
                    if cp -- "$restore" "$savepath"
                    echo "Backup saved to $savepath"
                    else
                        echo "Failed to save backup to $savepath"
                        echo "Save it manually."
                        exit
                    end
                end
            end
            rm -- $old
        echo "Removed old backup: $old"
            printf '    %s\n' $old
        end
    else
        echo "Backup file $restore does not exist."
        exit
    end
end
if test "$argv[1]" = "--restore"
    restore
    exit
end

function croninstall
if not type -q crontab
    echo "crontab is not installed. Do you want to install it now? (Only on Debian-based systems) [y/n]"
    read -P "Install crontab? " crony
    if test "$crony" = "y"
        if sudo apt update && sudo apt install cron && sudo systemctl enable --now cron
            echo "crontab installed successfully."
        else
            echo "Failed to install crontab."
            echo "crontab is required. Please install it manually. Exiting."
            exit
        end
    else
        echo "crontab is required. Please install it manually. Exiting."
        exit
    end
end
    set minutes (math "$interval * 60")
if test "$minutes" -lt 60
    set cront "*/$minutes * * * *"
else if test (math "$minutes % 60") -eq 0
    set hours (math "$minutes / 60")
    set cront "0 */$hours * * *"
else
    echo "This interval cannot be represented by a simple cron schedule. Please set the interval to a whole number of hours with --setup."
    exit
end
    set cronjob "$cront $dir/sbm.fish --backup # sbm"
        if crontab -l 2>/dev/null | string match -q '*# sbm*'
        echo "SBM cron job is already installed."
        exit
        end
        if begin
        crontab -l 2>/dev/null
        echo "$cronjob"
        end | crontab -
        echo "Cron job installed: $cronjob"
        read -P "Do you want to start the cron service now? [y/n]: " startcron
        if test "$startcron" = "y"
            if sudo systemctl enable --now cron
                echo "Cron service started."
            else
                echo "Failed to start cron service. Please start it manually."
                exit
            end
        else
        echo "If cron service not started, start it manually."
        end
    else
    echo "Failed to install cron job."
    return
    end
end
if test "$argv[1]" = "--croninstall"
    croninstall
    exit
end
function cronremove
    if crontab -l 2>/dev/null | string match -q '*# sbm*'
        if crontab -l 2>/dev/null | string match -v '*# sbm*' | crontab -
        echo "SBM cron job removed."
        else
        echo "Failed to remove SBM cron job."
        exit
        end
    else
        echo "SBM cron job is not installed."
    end
end
if test "$argv[1]" = "--cronremove"
    cronremove
    exit
end
function backup
    set timename (date "+%Y-%m-%d_%H-%M-%S")
    echo "Backing up to $desti/$timename"
    if tar -cf "$desti/$timename.tar.gz" --use-compress-program="gzip -$compl" -- $sources
        echo "Backup completed successfully."
        echo "Removing old backups..."
        set backups (ls -1t "$desti"/*.tar.gz 2>/dev/null)
        if test (count $backups) -gt $keep
            set old $backups[(math "$keep+1")..-1]
        rm -- $old
        echo "Removed old backup: $old"
            printf '    %s\n' $old
        end
    else
        echo "Backup failed!!!!!!!!!!!!!!!!!!!!!"
        echo " try running the script with --setup to reconfigure your config.json file."
        return 1
    end
end
if test "$argv[1]" = "--backup"
    backup
    exit
end
while true
backup
set remaining (math "$interval * 3600")
while test $remaining -gt 0
set h (math "floor($remaining / 3600)")
set m (math "floor(($remaining % 3600) / 60)")
set s (math "$remaining % 60")
printf "\rNext backup in: %02d:%02d:%02d" $h $m $s
sleep 1
set remaining (math "$remaining - 1")
end
echo
end