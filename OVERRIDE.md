# Overrides

This file is generated from `include\override-catalog.psd1`. Don't edit it. A change goes in the catalog, and this file is generated again.

## Where the file goes

Put your settings in `overrides\overrides.psd1` in the project folder. Git ignores that folder, so an upgrade never touches it. The file is a PowerShell data file holding one hashtable of constant values. Each value is a quoted string, a number, `$true`, `$false` or a list of those. Save it as UTF-8 with a BOM when it holds non-ASCII text. A key you leave out takes its shipped value.

For example, with settings at their shipped values:

```powershell
@{
    ComputerName = 'WIN2025'
    CpuCount = 2
}
```

To make the file from an older copy of the project, see [UPGRADE.md](UPGRADE.md).

## Precedence

A value given on the command line wins. Without one, a build profile's value applies, for the keys whose row says a profile sets them. Without that, the override file's value applies, and without that, the shipped value. A command-line value that differs from the override file's is logged as INFO.

## What a run logs

With no override file, a run logs one INFO line saying so, and the shipped settings apply. With one, it logs one INFO line naming the file, its SHA-256 and each setting it applied, with secret values shown as `<set>`. A key left empty gives a WARN, and its shipped value applies. A run stops when the file can't be read, holds a value that isn't a constant, holds an unknown key, or holds a value outside a key's permitted values.

## Settings

| Key | What it changes | How to override | Default | Permitted values | Why this default | Secret |
|---|---|---|---|---|---|---|
| `ComputerName` | The default of `-ComputerName`, described in the README and the script's help. | `overrides\overrides.psd1`, key `ComputerName`. build-lab passes it, so in a build-lab run set it in build-lab's file. `-ComputerName` on the command line also sets it, and the command line wins. | `WIN2025` | Text matching the pattern `^(?!-)(?!.*-$)[A-Za-z0-9-]{1,15}$`, ignoring case. | A short name that says what the VM runs and fits the 15-character NetBIOS limit. | no |
| `CpuCount` | The default of `-CpuCount`, described in the README and the script's help. | `overrides\overrides.psd1`, key `CpuCount`. build-lab passes it, so in a build-lab run set it in build-lab's file. `-CpuCount` on the command line also sets it, and the command line wins. | 2 | A whole number from 1 to 64. | Enough for Windows Setup and a lab role without crowding the host. | no |
| `DefaultGateway` | The default of `-DefaultGateway`, described in the README and the script's help. | `overrides\overrides.psd1`, key `DefaultGateway`. build-lab passes it when it has one, and then build-lab's value is used. `-DefaultGateway` on the command line also sets it, and the command line wins. | None | Text matching the pattern `^((25[0-5]\|2[0-4][0-9]\|1[0-9][0-9]\|[1-9]?[0-9])\.){3}(25[0-5]\|2[0-4][0-9]\|1[0-9][0-9]\|[1-9]?[0-9])$`, ignoring case. | The gateway differs per host and network, so the script can't guess one. | no |
| `DiskGB` | The default of `-DiskGB`, described in the README and the script's help. | `overrides\overrides.psd1`, key `DiskGB`. build-lab passes it, so in a build-lab run set it in build-lab's file. `-DiskGB` on the command line also sets it, and the command line wins. | 60 | A whole number from 20 to 2048. | Room for Windows Server 2025 with Desktop Experience and a lab role, on a sparse disk that grows only as it fills. | no |
| `DnsServer` | The default of `-DnsServer`, described in the README and the script's help. | `overrides\overrides.psd1`, key `DnsServer`. build-lab passes it, so in a build-lab run set it in build-lab's file. `-DnsServer` on the command line also sets it, and the command line wins. | `8.8.8.8` | Text matching the pattern `^((25[0-5]\|2[0-4][0-9]\|1[0-9][0-9]\|[1-9]?[0-9])\.){3}(25[0-5]\|2[0-4][0-9]\|1[0-9][0-9]\|[1-9]?[0-9])$`, ignoring case. | A public resolver that answers from any network the VM lands on. | no |
| `Edition` | The default of `-Edition`, described in the README and the script's help. | `overrides\overrides.psd1`, key `Edition`. `-Edition` on the command line also sets it, and the command line wins. | `Standard` | One of Standard, Datacenter. | The edition most lab roles need. | no |
| `GuestOS` | The VMX guestOS value, the guest operating system type Workstation shows for the VM. | `overrides\overrides.psd1`, key `GuestOS`. | `windows2022srvnext-64` | 1 to 64 letters, digits or hyphens. Set it to the identifier your Workstation version uses when the VM shows a guest OS warning. | The VMware Workstation 17 identifier for Windows Server 2025. | no |
| `ImageNameDatacenter` | The install image name Windows Setup uses when the edition is Datacenter. | `overrides\overrides.psd1`, key `ImageNameDatacenter`. | `Windows Server 2025 Datacenter Evaluation (Desktop Experience)` | 1 to 256 characters on one line. It must match an image name in the ISO's install.wim exactly. The README's Image Name Verification shows how to read them. | The Desktop Experience image name on Windows Server 2025 evaluation media. | no |
| `ImageNameStandard` | The install image name Windows Setup uses when the edition is Standard. | `overrides\overrides.psd1`, key `ImageNameStandard`. | `Windows Server 2025 Standard Evaluation (Desktop Experience)` | 1 to 256 characters on one line. It must match an image name in the ISO's install.wim exactly. The README's Image Name Verification shows how to read them. | The Desktop Experience image name on Windows Server 2025 evaluation media. | no |
| `InputLocale` | The answer file's InputLocale, the input language and keyboard layout. | `overrides\overrides.psd1`, key `InputLocale`. | `en-US` | A language name such as `en-GB` in any letter case, a locale ID and keyboard layout such as `0409:00000409`, or several of those separated by semicolons, the first being the default. | The language of the evaluation media this project targets. | no |
| `LogPath` | The default of `-LogPath`, described in the README and the script's help. | `overrides\overrides.psd1`, key `LogPath`. build-lab passes its own log folder, so in a build-lab run this key isn't used. `-LogPath` on the command line also sets it, and the command line wins. | The `logs` folder beside the script | A folder path. A relative path in the override file resolves from the script's folder. | The logs stay with the copy of the script that wrote them, wherever it was started from. | no |
| `NetworkType` | The default of `-NetworkType`, described in the README and the script's help. | `overrides\overrides.psd1`, key `NetworkType`. build-lab passes it, so in a build-lab run set it in build-lab's file. `-NetworkType` on the command line also sets it, and the command line wins. | `nat` | One of nat, bridged, hostonly. | NAT gives the VM internet access through the host with no change to the host's own network. | no |
| `Organization` | The answer file's Organization, the name of the organization that owns the computer. | `overrides\overrides.psd1`, key `Organization`. | `Lab` | 1 to 63 characters on one line, the limit Microsoft documents for this answer file setting. | A neutral name for a lab machine. | no |
| `PostSetupDelayMinutes` | The default of `-PostSetupDelayMinutes`, described in the README and the script's help. | `overrides\overrides.psd1`, key `PostSetupDelayMinutes`. `-PostSetupDelayMinutes` on the command line also sets it, and the command line wins. | 5 | A whole number from 0 to 60. | A ping reply can come before the specialize pass and the VMware Tools install finish, so the script waits before it ejects the media. | no |
| `ProductKey` | The default of `-ProductKey`, described in the README and the script's help. | `overrides\overrides.psd1`, key `ProductKey`. `-ProductKey` on the command line also sets it, and the command line wins. | None | Text matching the pattern `^([A-Z0-9]{5}-){4}[A-Z0-9]{5}$`, ignoring case. | Evaluation media installs with no key. Retail and volume license media need one to stay unattended. | yes |
| `RamMB` | The default of `-RamMB`, described in the README and the script's help. | `overrides\overrides.psd1`, key `RamMB`. build-lab passes it, so in a build-lab run set it in build-lab's file. `-RamMB` on the command line also sets it, and the command line wins. | 4096 | A whole number from 512 to 65536. | Comfortable for Windows Server 2025 with Desktop Experience in a lab, and small enough for most hosts. | no |
| `RestartTimeoutMinutes` | The default of `-RestartTimeoutMinutes`, described in the README and the script's help. | `overrides\overrides.psd1`, key `RestartTimeoutMinutes`. `-RestartTimeoutMinutes` on the command line also sets it, and the command line wins. | 10 | A whole number from 1 to 60. | The restart after the drive removal is a plain reboot, much faster than Setup. | no |
| `ShowConsole` | The default of `-ShowConsole`, described in the README and the script's help. | `overrides\overrides.psd1`, key `ShowConsole`. `-ShowConsole` on the command line also sets it, and the command line wins. | `$false` | $true or $false. | A headless run puts no console window in front of you, and the VM still opens in the Workstation library. | no |
| `ShutdownTimeoutMinutes` | The default of `-ShutdownTimeoutMinutes`, described in the README and the script's help. | `overrides\overrides.psd1`, key `ShutdownTimeoutMinutes`. `-ShutdownTimeoutMinutes` on the command line also sets it, and the command line wins. | 5 | A whole number from 1 to 30. | Long enough for a soft shutdown of a freshly installed server. | no |
| `SubnetMask` | The default of `-SubnetMask`, described in the README and the script's help. | `overrides\overrides.psd1`, key `SubnetMask`. build-lab passes it, so in a build-lab run set it in build-lab's file. `-SubnetMask` on the command line also sets it, and the command line wins. | `255.255.255.0` | Text matching the pattern `^((25[0-5]\|2[0-4][0-9]\|1[0-9][0-9]\|[1-9]?[0-9])\.){3}(25[0-5]\|2[0-4][0-9]\|1[0-9][0-9]\|[1-9]?[0-9])$`, ignoring case. | Workstation allocates its NAT network as a /24. | no |
| `SystemLocale` | The answer file's SystemLocale, the default language for non-Unicode programs. | `overrides\overrides.psd1`, key `SystemLocale`. | `en-US` | A culture name such as `en-GB`, in any letter case. | The language of the evaluation media this project targets. | no |
| `TempPath` | The default of `-TempPath`, described in the README and the script's help. | `overrides\overrides.psd1`, key `TempPath`. build-lab passes a folder per build, so in a build-lab run this key isn't used. `-TempPath` on the command line also sets it, and the command line wins. | `%TEMP%\VMDeploy` | A folder path. A relative path in the override file resolves from the script's folder. | A per-user scratch folder the script can always write to. | no |
| `TimeZone` | The default of `-TimeZone`, described in the README and the script's help. | `overrides\overrides.psd1`, key `TimeZone`. `-TimeZone` on the command line also sets it, and the command line wins. | `Pacific Standard Time` | A Windows time zone ID, as `tzutil /l` lists them. | The author's time zone. | no |
| `TimeoutMinutes` | The default of `-TimeoutMinutes`, described in the README and the script's help. | `overrides\overrides.psd1`, key `TimeoutMinutes`. build-lab passes it, so in a build-lab run set it in build-lab's file. `-TimeoutMinutes` on the command line also sets it, and the command line wins. | 90 | A whole number from 1 to 1440. | Covers a full unattended install on a slow host with room to spare. | no |
| `UserLocale` | The answer file's UserLocale, the formats for dates, times, currency and numbers. | `overrides\overrides.psd1`, key `UserLocale`. | `en-US` | A culture name such as `en-GB`, in any letter case. | The language of the evaluation media this project targets. | no |
| `VmName` | The default of `-VmName`, described in the README and the script's help. | `overrides\overrides.psd1`, key `VmName`. build-lab passes it, so in a build-lab run set it in build-lab's file. `-VmName` on the command line also sets it, and the command line wins. | `WS2025-Server` | Text matching the pattern `^[^\\/:*?"<>\|]{1,64}$`, ignoring case. | Names the operating system the VM runs. | no |

## Retired keys

None.

## Not covered

These can't be set in the override file.

| Setting | Why it isn't covered |
|---|---|
| `AdminPassword` | A credential, and mandatory, so it is passed for each run and never stored as a setting. |
| `IsoPath` | Mandatory, and the ISO is chosen for each run. |
| `StaticIpAddress` | Each VM needs its own address. |
| `UILanguage` | It must match the language of the media, which is en-US on the evaluation media this project targets. |
| `UILanguageFallback` | It must match the language of the media, which is en-US on the evaluation media this project targets. |
| `VMware Workstation install folder` | The script searches the two standard Program Files folders. A Workstation installed elsewhere needs a script change. |
| `VmStoragePath` | Mandatory, and where each VM goes is chosen for each run. |
| `virtualHW.version` | Tied to the NVMe and PCIe layout the VMX was tested with. |

## Security

Secret values sit in plain text in `overrides\overrides.psd1` on disk, and are masked only in logs. A product key set here is written into the answer file and its ISO, as one passed on the command line is.

## Other projects

Each lab project documents its own overrides:

- [build-lab](https://github.com/0x44616e69656c/build-lab/blob/main/OVERRIDE.md)
- [new-AdDomain](https://github.com/0x44616e69656c/new-AdDomain/blob/main/OVERRIDE.md)
