# SBM
## server-backup-manager
A fish script that automatically creates backups of selected server folders to a chosen location. For example, an external drive.

## Installing Fish
Debian:
```bash
sudo apt install fish
```

Fedora:
```bash
sudo dnf install fish
```

Arch Linux:
```bash
sudo pacman -S fish
```

## Installing jq
Debian:
```bash
sudo apt install jq
```

Fedora:
```bash
sudo dnf install jq
```

Arch Linux:
```bash
sudo pacman -S jq
```

## Installing cron
Debian:
```bash
sudo apt install cron
```

Fedora:
```bash
sudo dnf install cronie
```

Arch Linux:
```bash
sudo pacman -S cronie
```

## First use:

```bash
chmod +x sbm.fish
```

Execution:
```bash
./sbm.fish
```
(This will create a config.json file.)

After that, set it up using this command:
```bash
./sbm.fish --setup
```

It will ask for a folder where the backups will be stored. If it does not exist, the script can create it.

Next, it asks for the compression level. You can enter a number from 1 to 9. Level 1 provides low compression. It uses less CPU, but results in a larger backup file. While level 9 produces a much smaller output file but consumes much more CPU.

Then it asks how many backup files you want to keep. For example, if you enter 5, the 5 most recent backups will always be kept in the output folder. Olders will be removed.

Then it asks how often you want to create backups. You need to specify this in hours. For example, entering 1 means 1 hour, 1.5 means an hour and a half, and you can even enter 0.5. Anything greater than 0 is fine.

# Usage

## Builtin mode:

Just run the script, and it will automatically create the backups.
```bash
./sbm.fish
```

## Cron (Recommended):

Better timed execution.

Ensure that cron is installed on the device. If it is not, the script will notify you. 

Run this command first:
```bash
./sbm.fish --croninstall
```

This will install the cron configuration, and start and enable the cron service.

To stop the automation, run this:
```bash
./sbm.fish --cronremove
```

## Restore:

```bash
./sbm.fish --restore
```
This lists the available backups, and you must enter the filename of the backup you wish to restore. Before performing the restore, it creates a new backup of the current state. After the restore is complete, it deletes the oldest backup; however, if the backup being restored happens to be the oldest one, it creates a copy of it before deletion.

## Just backup:
```bash
./sbm.fish --backup
```
This creates a backup, without a schedule.