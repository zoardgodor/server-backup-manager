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

## Usage

Just run the script, and it will automatically create the backups.
```bash
./sbm.fish
```