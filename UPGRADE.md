# Upgrading to 1.1.0

> **Not tested yet.** These steps haven't been through a live run. Until they have, keep your old folder until the new one has built a VM for you.

1.1.0 moves every setting you might change out of the script and into an override file, `overrides\overrides.psd1`, that upgrades leave alone. [OVERRIDE.md](OVERRIDE.md) lists every setting. From this release on, an upgrade is a `git pull` or a fresh copy plus your `overrides` folder, and that's it.

Coming from 1.0.2, 1.0.1 or 1.0, the steps are the same. This one upgrade still needs a little care if you edited `New-VMwareWorkstationVM.ps1`. The usual edits were the `$imageName` names for non-evaluation media, the `-Edition`, `-TimeZone` and `-ProductKey` defaults, `guestOS`, and the locale lines of the answer file. A small script, `Export-OverrideFile.ps1`, reads your old copy without running it and writes the settings you changed into the new override file.

## What else changes

- **The log folder.** Without `-LogPath`, the logs now always go to the `logs` folder beside the script. Started with `powershell.exe -File` from another folder, 1.0.x wrote them under that other folder instead.
- **Relative paths.** A relative `-LogPath`, `-TempPath` or `-VmStoragePath` now works after a `Set-Location`. It resolves from your current location, as the README always said for `-LogPath`.
- **A missing drive.** A `-LogPath`, `-TempPath` or `-VmStoragePath` on a drive that doesn't exist stops the run with one plain message, before the VM or any of its files is created.
- **Locale values.** The locale settings take any letter case, so `en-gb` works as well as `en-GB`.
- **build-lab.** build-lab passes most settings on the command line, and the command line wins. The settings it doesn't pass, such as `Edition`, `TimeZone` and `ProductKey`, come from this project's override file in a build-lab run too.

## If you never edited the script

From a clone, in the folder above `New-VMwareWorkstationVM`:

```powershell
cd .\New-VMwareWorkstationVM
git pull
```

From a zip, download the new zip, extract it beside the old folder, and use the new folder. Unblock it first, from inside the extracted folder:

```powershell
Get-ChildItem -Recurse -File | Unblock-File
```

## If you edited the script

Work from the folder above `New-VMwareWorkstationVM`. Rename your old copy so it's kept as it is:

```powershell
Rename-Item -Path .\New-VMwareWorkstationVM -NewName New-VMwareWorkstationVM-old
```

Get a fresh copy. From GitHub:

```powershell
git clone https://github.com/0x44616e69656c/New-VMwareWorkstationVM.git
```

Or from a zip, extract it into a new `New-VMwareWorkstationVM` folder beside the old one, then unblock it:

```powershell
cd .\New-VMwareWorkstationVM
Get-ChildItem -Recurse -File | Unblock-File
cd ..
```

Preview what the migration would write. `-WhatIf` writes no override file, and the console lists every setting it read:

```powershell
cd .\New-VMwareWorkstationVM
.\Export-OverrideFile.ps1 -SourcePath ..\New-VMwareWorkstationVM-old -WhatIf
```

Then write it, and read the result:

```powershell
.\Export-OverrideFile.ps1 -SourcePath ..\New-VMwareWorkstationVM-old
Get-Content .\overrides\overrides.psd1
```

What the script does with each kind of setting:

- **A setting you changed** is written to the file, with a comment naming the line it came from. A value from the answer file is read as the XML it was, so an old `A&amp;B` comes across as `A&B`.
- **A setting you never changed** is left out, so the shipped value applies and later releases can improve it.
- **A value the new release would refuse**, such as a `-RamMB` default outside 512 to 65536, is written commented out with the reason. Correct it and remove the `#`.
- **A value your old script worked out at run time** can't be read without running it, so it's listed for you to set by hand.
- **An existing override file** is never overwritten. The new file goes to `overrides\migrated-<date>-<time>\` for you to merge by hand.

Every run leaves a log in the `logs` folder, one row per setting, with any product key shown as `<set>`.

Run one build with the new folder and check the log. Its first lines include one INFO line naming the override file, its SHA-256 and each setting it applied. 1.1.0 changes no shipped default, so there's no line about a changed default. When that build looks right, the old folder can go.

## Next time

Keep your settings in `overrides\overrides.psd1`. Git ignores the `overrides` folder, so `git pull` never touches it. A zip user copies that one folder into the new copy:

```powershell
Copy-Item -Path .\New-VMwareWorkstationVM-old\overrides -Destination .\New-VMwareWorkstationVM -Recurse
```
