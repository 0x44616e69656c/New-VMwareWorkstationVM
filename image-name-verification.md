# Verifying and Updating the `/IMAGE/NAME` Value for New Media

Standalone procedure for picking the correct image names for
[New-VMwareWorkstationVM.ps1](New-VMwareWorkstationVM.ps1) when switching to a
different Windows Server ISO (a different version, edition set, or channel, such as
evaluation against volume-license or retail). The names go in your override file as the
`ImageNameStandard` and `ImageNameDatacenter` settings, so the script itself stays as
shipped. [OVERRIDE.md](OVERRIDE.md) shows where the file goes.

## Why this matters

`New-AutoUnattendXml` selects the edition to install via
`<ImageInstall><OSImage><InstallFrom><MetaData><Key>/IMAGE/NAME</Key>`. The value is the
override file's `ImageNameStandard` or `ImageNameDatacenter` for the edition in use, or
the shipped name from the script's `$imageName` switch when the file doesn't set one.
This string **must match an image name in the
target ISO's `install.wim` exactly**, including whether "Evaluation" appears in the
name, bracketing, and casing.

If it does not match:

- Windows Setup does **not** show an interactive picker (the script sets
  `<WillShowUI>Never</WillShowUI>`).
- Setup silently falls back to **image index 1** in the WIM (often a Server Core
  image, not the Desktop Experience edition you intended).
- The unattended install then fails late, during the windowsPE pass, with
  **"Setup has failed to validate the product key"**, a misleading error that has
  nothing to do with `-ProductKey` and everything to do with the image-name mismatch.

## Prerequisites

- Run as a user with permission to mount disk images (`Mount-DiskImage` /
  `Dismount-DiskImage`).
- `Get-WindowsImage` (part of the built-in `Dism` PowerShell module).
- The target ISO accessible from the machine you're running the check on (it does
  **not** need to be the machine that runs the deploy script, but the resulting
  image names must match the ISO the deploy script will actually use).

## Step 1 - Mount the ISO

```powershell
$isoPath = "D:\iso\<your-iso-filename>.iso"
$mount = Mount-DiskImage -ImagePath $isoPath -PassThru
$driveLetter = ($mount | Get-Volume).DriveLetter
"Mounted at ${driveLetter}:"
```

## Step 2 - List the available Windows images

```powershell
Get-WindowsImage -ImagePath "${driveLetter}:\sources\install.wim" |
    Select-Object ImageIndex, ImageName |
    Format-Table -AutoSize
```

Example output from the SERVER_EVAL_x64FRE WS2025 media used on 2026-06-10:

```
ImageIndex ImageName
---------- ---------
         1 Windows Server 2025 Standard Evaluation
         2 Windows Server 2025 Standard Evaluation (Desktop Experience)
         3 Windows Server 2025 Datacenter Evaluation
         4 Windows Server 2025 Datacenter Evaluation (Desktop Experience)
```

Note exactly which row corresponds to the **Desktop Experience** variant of
**Standard** and **Datacenter** (or whichever editions `-Edition` needs to support).
The `ImageName` string is what goes into the override file.

## Step 3 - Check the install channel (`ei.cfg`)

```powershell
if (Test-Path "${driveLetter}:\sources\ei.cfg") {
    "--- ei.cfg ---"
    Get-Content "${driveLetter}:\sources\ei.cfg"
} else {
    "No ei.cfg, so likely retail or VL media"
}

if (Test-Path "${driveLetter}:\sources\pid.txt") {
    "--- pid.txt ---"
    Get-Content "${driveLetter}:\sources\pid.txt"
} else {
    "No pid.txt"
}
```

What this tells you:

| `ei.cfg` content | Meaning | `-ProductKey` implication |
| --- | --- | --- |
| `[Channel]` `eval`, `[VL]` `0` | Evaluation media | Omit `-ProductKey` (current script default leaves `<ProductKey>` out entirely). Image names typically include **"Evaluation"**. |
| `[Channel]` `Retail` or `Volume`, `[VL]` `1` | Retail/VL media | Image names typically **omit** "Evaluation". Setup may require a product key. Pass `-ProductKey` with a real key, or research whether this media's `<ProductKey>` handling needs adjustment. This is not tested. |

## Step 4 - Dismount the ISO

```powershell
Dismount-DiskImage -ImagePath $isoPath
```

Don't skip this. A mounted ISO can interfere with the deploy script if it later
tries to use the same file (e.g. `vmrun`/`vmware-vdiskmanager` reading the same path).

## Step 5 - Set the names in the override file

Create `overrides\overrides.psd1` in the project folder, or add to it if you already
have one. It holds one hashtable, and the two settings look like this:

```powershell
@{
    ImageNameStandard   = 'Windows Server 2025 Standard Evaluation (Desktop Experience)'
    ImageNameDatacenter = 'Windows Server 2025 Datacenter Evaluation (Desktop Experience)'
}
```

Replace the two strings with the **exact** strings from Step 2's `Get-WindowsImage`
output for the Desktop Experience variants of Standard and Datacenter. Copy-paste
directly from the `Get-WindowsImage` output rather than retyping, since
bracketing/spacing/casing differences are exactly what causes the silent fallback
described above. Supporting an edition other than Standard or Datacenter is still a
script change, to `-Edition`'s `ValidateSet` and the `$imageName` switch.

The next run's log has an INFO line naming the override file and each setting it
applied, so you can see the names were picked up.

## Step 6 (optional but recommended) - Validate without a full rebuild

A full deploy-rebuild cycle takes ~20-30 minutes. You can validate that the new
image name renders correctly in the generated `autounattend.xml` in seconds,
without creating a VM. Run these from the repository root, where
`New-VMwareWorkstationVM.ps1` lives:

```powershell
$scriptPath = (Resolve-Path '.\New-VMwareWorkstationVM.ps1').Path
$src = Get-Content $scriptPath -Raw
$ast = [System.Management.Automation.Language.Parser]::ParseInput($src, [ref]$null, [ref]$null)
$funcs = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $args[0].Name -in @('New-AutoUnattendXml','ConvertTo-CidrPrefixLength','ConvertTo-XmlText') }, $true)
. ([scriptblock]::Create((($funcs | ForEach-Object { $_.Extent.Text }) -join "`n`n")))

$xmlText = New-AutoUnattendXml -ComputerName 'WIN2025' -AdminPasswordPlainText 'Test123!' `
    -TimeZone 'Pacific Standard Time' -ImageName 'Windows Server 2025 Standard Evaluation (Desktop Experience)' `
    -ProductKey '' -StaticIpAddress '192.168.1.50' -SubnetMask '255.255.255.0' `
    -DefaultGateway '192.168.1.1' -DnsServer '192.168.1.1' -MacAddress '00:50:56:00:00:01' `
    -InputLocale 'en-US' -SystemLocale 'en-US' -UserLocale 'en-US' -Organization 'Lab'

([xml]$xmlText).unattend.settings |
    Where-Object { $_.pass -eq 'windowsPE' } |
    ForEach-Object { $_.component.ImageInstall.OSImage.InstallFrom.MetaData.Value }
```

The last line should print back exactly the `ImageName` you passed in. An XML parse
error, if the value broke the file, shows up instead. This confirms the value flows
through correctly. It does **not** confirm the value matches the ISO, which is what
Steps 1 and 2 are for.

If you changed the script itself, for another edition, also run the standard checks used throughout this project:

```powershell
$scriptPath = (Resolve-Path '.\New-VMwareWorkstationVM.ps1').Path
$errors = $null; $tokens = $null
[void][System.Management.Automation.Language.Parser]::ParseFile(
    $scriptPath, [ref]$tokens, [ref]$errors)
if ($errors.Count -gt 0) { $errors | Format-List } else { "No parse errors" }

Invoke-ScriptAnalyzer -Path $scriptPath |
    Format-Table -AutoSize
```

## Step 7 - Re-run the deploy

Go. Deploy your server. It should work now.

## Quick reference: what "wrong" looks like

If you skip this process and the image name doesn't match, the symptoms are:

1. `vmware.log` shows a clean power-on, with no PCI, SCSI or firmware errors.
2. The VM boots into the **Windows Server Setup GUI** (not stuck at a boot menu).
3. Setup immediately shows **"Setup has failed to validate the product key"**.

That combination is the signature of an `/IMAGE/NAME` mismatch, not a product-key
problem. Come back to this document rather than touching `-ProductKey` or
`<ProductKey>` handling.
