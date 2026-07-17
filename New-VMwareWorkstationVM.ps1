<#
.SYNOPSIS
    Deploys an unattended Windows Server 2025 VM to VMware Workstation.
.DESCRIPTION
    Creates a VMware Workstation VM from a Windows Server 2025 ISO image.
    Generates an autounattend.xml answer file, packages it into a secondary
    bootable ISO mounted as a second CD drive, and starts the VM unattended.
    Optionally waits for the VM to come online by pinging a static IP address.
.EXAMPLE
    $pw = ConvertTo-SecureString 'P@ssw0rd!' -AsPlainText -Force
    .\New-VMwareWorkstationVM.ps1 -IsoPath "C:\ISOs\WS2025.iso" -AdminPassword $pw -VmStoragePath "C:\VMs"
.EXAMPLE
    # -NetworkType defaults to 'nat', which puts the adapter on VMnet8. Workstation always
    # allocates a NAT network as a Class C and reserves fixed roles inside it:
    #   net.1            host virtual network adapter (reserved)
    #   net.2            NAT device -- the default gateway AND the DNS server
    #   net.3 - net.127  free for static IP addresses
    #   net.128 - net.254  virtual DHCP server's dynamic pool
    # So -StaticIpAddress must be net.3-net.127 and -DefaultGateway must be net.2. An address
    # in the DHCP pool risks a conflict; an address outside the subnet entirely leaves the
    # guest unreachable and the online check times out. The subnet itself is assigned when
    # Workstation is installed and differs per host -- look yours up in
    # Edit > Virtual Network Editor > VMnet8. 192.168.220.0/24 below is illustrative only.
    $pw = ConvertTo-SecureString 'P@ssw0rd!' -AsPlainText -Force
    .\New-VMwareWorkstationVM.ps1 -IsoPath "C:\ISOs\WS2025.iso" -AdminPassword $pw `
        -VmName "LabServer01" -RamMB 8192 -DiskGB 120 -CpuCount 4 `
        -VmStoragePath "C:\VMs" -StaticIpAddress "192.168.220.50" -DefaultGateway "192.168.220.2"
.NOTES
    Version:      1.0.2
    Author:       Daniel Owen
    Repository:   https://github.com/0x44616e69656c/New-VMwareWorkstationVM
    Release Date: 2026-07-17
    Requirements: VMware Workstation 17+, vmrun.exe, vmware-vdiskmanager.exe,
                  Windows ADK not required (uses built-in IMAPI2 for ISO creation).
                  Static IP requires the inbox vmxnet3 driver to be present in the
                  Windows Server 2025 media; without it the NIC is invisible during
                  the specialize pass and the static config silently falls back to DHCP.
                  The -Edition image names map to /IMAGE/NAME values that must EXACTLY match
                  the target media; verify with 'dism /Get-WimInfo' and update the $imageName
                  switch in the Variables region if they differ.
                  VM firmware is BIOS with an MBR disk (not UEFI/GPT): UEFI Windows media
                  shows a "Press any key to boot from CD or DVD" prompt that headless vmrun
                  deployments can never answer, leaving the VM looping the EFI boot menu.
                  -DiskGB is capped at 2048 (2 TB) -- the addressing limit of an MBR boot
                  partition.
                  OS disk is attached as nvme0 (not scsi0/lsisas1068): on this host,
                  virtualHW.version 19's lsisas1068 SCSI controller could not obtain a PCI
                  slot under BIOS firmware ("No PCIe slot available for SCSI0" /
                  "Unable to allocate a PCI SCSI adapter"), even with the pciBridge0/4-7
                  root-port block present. NVMe is the inbox WS2025 disk driver and has
                  established BIOS-boot-ROM support in Workstation.
                  VMware Tools is silently installed during specialize (searches drive
                  letters D-H for VMwareToolsUpgrader.exe to identify the tools ISO at
                  sata0:2, then runs that drive's setup.exe -- the Windows install ISO
                  also has its own setup.exe at root, hence the marker-file check); if
                  the tools ISO was not found at script start, this step is a harmless
                  no-op.
                  After 'vmrun start', the script also launches vmware.exe against the new
                  VMX so the VM appears in the Workstation Library without manually
                  opening it; failure to do so is logged as a WARN and does not fail
                  the deployment.
                  Once the VM is online and the post-setup delay elapses, the script ejects
                  sata0:0/sata0:1/sata0:2 (as before), then power-cycles the VM to remove
                  those CD/DVD drive entries from the VMX entirely: soft-stops the VM
                  (-ShutdownTimeoutMinutes, default 5, to confirm power-off via 'vmrun
                  list'), edits the VMX while no vmware-vmx.exe process owns it
                  (sata0.present, the controller, is left in place), then restarts and
                  waits up to -RestartTimeoutMinutes (default 10) for the VM to respond to
                  ping again. This power cycle is required because VMware Workstation
                  rewrites the VMX from its in-memory device list at power-off, silently
                  discarding any edit made while the VM is running -- confirmed via a live
                  before/after VMX comparison (see gotchas.md 2026-06-12). If the soft stop
                  or power-off confirmation fails, the CD/DVD drives are left ejected but
                  still defined (the v0.4.3 end state) and the deployment is NOT failed. If
                  the post-removal restart fails, this IS treated as a deployment failure
                  (ERROR + re-throw), since the VM would otherwise be left powered off; the
                  manual 'vmrun start' command is logged for recovery. This only runs in the
                  -StaticIpAddress + online-confirmed path.
                  In addition to the CSV log, the entire run is wrapped in Start-Transcript /
                  Stop-Transcript, writing a full text transcript (all host output and error
                  records, including stack traces) to
                  '<LogPath>\VMDeploy_<timestamp>_Transcript.txt'. If Start-Transcript fails
                  (e.g. a transcript is already active in the session), this is logged as a
                  WARN and the deployment proceeds without one.
                  Log/transcript/temp-directory setup fails fast: Initialize-Log creates the
                  CSV (writing its header once) via explicit -ErrorAction Stop / .NET calls
                  that already throw, and the TempPath/answerTempDir/vmDirectory creation loop
                  uses -ErrorAction Stop too, so a bad -LogPath/-TempPath/-VmStoragePath is
                  reported immediately instead of surfacing later as a misleading file-write
                  error. This is deliberately NOT done via a script-wide
                  $ErrorActionPreference = 'Stop' -- vmrun.exe/vmware-vdiskmanager.exe are
                  invoked with 2>&1 and any stderr line becomes a terminating error under a
                  global 'Stop' (confirmed on this host's PS 5.1), which would break the
                  exit-code/output pattern-matching in Invoke-WithRetry and turn several
                  intentionally non-fatal steps (CD/DVD eject, soft-stop, VMX edit) into hard
                  deployment failures. Everywhere outside the bootstrap uses explicit
                  -ErrorAction Stop instead. If Initialize-Log itself fails, the error is
                  written to stderr (no CSV/transcript exists yet) and the script exits
                  non-zero without further attempts to log.
    Event Log Source: N/A (file CSV logging only)
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$IsoPath,

    [Parameter(Mandatory)]
    [SecureString]$AdminPassword,

    [ValidatePattern('^[^\\/:*?"<>|]{1,64}$')]
    [string]$VmName = 'WS2025-Server',

    [Parameter(Mandatory)]
    [string]$VmStoragePath,

    [ValidateRange(512, 65536)]
    [int]$RamMB = 4096,

    [ValidateRange(1, 64)]
    [int]$CpuCount = 2,

    [ValidateRange(20, 2048)]
    [int]$DiskGB = 60,

    [ValidatePattern('^(?!-)(?!.*-$)[A-Za-z0-9-]{1,15}$')]
    [string]$ComputerName = 'WIN2025',

    [string]$TimeZone = 'Pacific Standard Time',

    [ValidateSet('Standard', 'Datacenter')]
    [string]$Edition = 'Standard',

    [ValidatePattern('^([A-Z0-9]{5}-){4}[A-Z0-9]{5}$')]
    [string]$ProductKey,

    [ValidateSet('nat', 'bridged', 'hostonly')]
    [string]$NetworkType = 'nat',

    [ValidatePattern('^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$')]
    [string]$StaticIpAddress,

    [ValidatePattern('^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$')]
    [string]$SubnetMask = '255.255.255.0',

    [ValidatePattern('^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$')]
    [string]$DefaultGateway,

    [ValidatePattern('^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$')]
    [string]$DnsServer = '8.8.8.8',

    [switch]$ShowConsole,

    [ValidateRange(1, 1440)]
    [int]$TimeoutMinutes = 90,

    # A ping response confirms the VM is reachable but not that Windows Setup's
    # specialize pass (including the silent VMware Tools install) has finished --
    # this delay runs after the ping succeeds and before installation media is
    # ejected, so the CD/DVD drives aren't pulled out from under a running installer.
    [ValidateRange(0, 60)]
    [int]$PostSetupDelayMinutes = 5,

    # After ejecting installation media, the VM is power-cycled (soft shutdown, edit the
    # VMX to remove the CD/DVD drive entries, restart) -- VMware Workstation rewrites the
    # VMX from its in-memory device list at power-off, so this is the only way drive
    # removal survives. This is how long to wait for the soft shutdown to complete
    # before giving up on drive removal (the VM is left running with media ejected but
    # drives still defined, as in v0.4.3).
    [ValidateRange(1, 30)]
    [int]$ShutdownTimeoutMinutes = 5,

    # How long to wait for the VM to respond to ping again after the post-removal
    # restart. This is just a reboot (Setup's specialize pass already completed), so it
    # should be much faster than -TimeoutMinutes.
    [ValidateRange(1, 60)]
    [int]$RestartTimeoutMinutes = 10,

    # Anchored to the script's own directory (not the current working directory) so the
    # CSV log and transcript always land next to the script regardless of where it is
    # invoked from. A relative value passed explicitly still resolves from the working
    # directory. If $PSScriptRoot is empty (e.g. the script body is run interactively
    # rather than from a file), this falls back to a working-directory-relative '.\logs'.
    [string]$LogPath = "$(if ($PSScriptRoot) { Join-Path $PSScriptRoot 'logs' } else { '.\logs' })",

    [string]$TempPath = "$env:TEMP\VMDeploy"
)

#region Functions

function Initialize-Log {
    param (
        [Parameter(Mandatory)]
        [string]$LogFilePath
    )

    # Failures here happen before any log file exists, so they cannot be reported
    # through Write-Log -- write to stderr directly and rethrow (terminating).
    try {
        $logDirectory = Split-Path -Path $LogFilePath -Parent
        if (-not (Test-Path -LiteralPath $logDirectory -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $logDirectory -Force -ErrorAction Stop
        }

        if (Test-Path -LiteralPath $LogFilePath) {
            throw "Refusing to overwrite an existing log file '$LogFilePath'."
        }

        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText(
            $LogFilePath,
            "Timestamp,Level,Message,ErrorDetail`r`n",
            $utf8NoBom)
    }
    catch {
        [Console]::Error.WriteLine(
            "Unable to initialize deployment logging at '$LogFilePath': $($_.Exception.Message)")
        throw
    }
}

function Write-Log {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
        Justification = 'Colored console status output is intentional for this interactive deployment script; the same events are also persisted to the CSV log file.')]
    param (
        [string]$Message,
        [string]$LogFilePath,
        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO',
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    $timestamp   = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $errorDetail = if ($ErrorRecord) { $ErrorRecord.Exception.Message } else { '' }

    # Console: human-readable colored line
    $consoleLine = "$timestamp [$Level] $Message"
    if ($errorDetail) { $consoleLine += " | $errorDetail" }
    $color = switch ($Level) {
        'WARN'  { 'Yellow' }
        'ERROR' { 'Red' }
        default { 'White' }
    }
    Write-Host $consoleLine -ForegroundColor $color

    # File: CSV row (every field quoted, embedded quotes doubled). UTF-8 without BOM
    # for consistency. Initialize-Log writes the header once before deployment begins.
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $csvRow = (@($timestamp, $Level, $Message, $errorDetail) | ForEach-Object {
        '"' + ($_ -replace '"', '""') + '"'
    }) -join ','
    [System.IO.File]::AppendAllText($LogFilePath, "$csvRow`r`n", $utf8NoBom)
}

function Invoke-WithRetry {
    param (
        [scriptblock]$Operation,
        [string]$OperationName,
        [string]$LogFilePath,
        [int]$RetryCount = 12,
        [int]$RetryDelaySeconds = 10
    )
    for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
        try {
            return & $Operation
        }
        catch {
            Write-Log "Attempt $attempt of $RetryCount for '$OperationName' failed." -LogFilePath $LogFilePath -Level 'WARN' -ErrorRecord $_
            if ($attempt -eq $RetryCount) {
                Write-Log "All $RetryCount attempts for '$OperationName' exhausted." -LogFilePath $LogFilePath -Level 'ERROR' -ErrorRecord $_
                throw
            }
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }
}

function Find-VMwareExecutable {
    param (
        [string]$ExecutableName,
        [string]$LogFilePath
    )
    $searchPaths = @(
        "${env:ProgramFiles(x86)}\VMware\VMware Workstation",
        "$env:ProgramFiles\VMware\VMware Workstation"
    )
    foreach ($candidatePath in $searchPaths) {
        $fullPath = Join-Path $candidatePath $ExecutableName
        if (Test-Path $fullPath) {
            Write-Log "Located $ExecutableName at: $fullPath" -LogFilePath $LogFilePath
            return $fullPath
        }
    }
    throw "$ExecutableName not found. Ensure VMware Workstation is installed and its directory is accessible."
}

function ConvertTo-CidrPrefixLength {
    param ([string]$SubnetMask)
    $binaryString = ($SubnetMask.Split('.') | ForEach-Object {
        [Convert]::ToString([int]$_, 2).PadLeft(8, '0')
    }) -join ''
    # A valid mask is a run of 1s followed by a run of 0s; '01' means non-contiguous.
    if ($binaryString -match '01') {
        throw "Invalid subnet mask '$SubnetMask': bits are not contiguous."
    }
    return ($binaryString.ToCharArray() | Where-Object { $_ -eq '1' }).Count
}

function New-VMwareMacAddress {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Pure function: builds and returns a MAC string; changes no system state.')]
    param ()
    # VMware honors a manually assigned MAC only within 00:50:56:00:00:00 -
    # 00:50:56:3F:FF:FF; the fourth octet must be 0x00-0x3F or Workstation overrides it.
    $octet4 = '{0:X2}' -f (Get-Random -Minimum 0 -Maximum 0x40)
    $octet5 = '{0:X2}' -f (Get-Random -Minimum 0 -Maximum 0x100)
    $octet6 = '{0:X2}' -f (Get-Random -Minimum 0 -Maximum 0x100)
    return "00:50:56:${octet4}:${octet5}:${octet6}"
}

function ConvertTo-XmlText {
    param (
        [string]$Value
    )

    # A [string]-typed parameter coerces $null to '' at bind time, so no null
    # guard is needed here: an omitted or $null argument arrives as ''.
    return [System.Security.SecurityElement]::Escape($Value)
}

function New-AutoUnattendXml {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Pure function: builds and returns the answer-file XML string; changes no system state.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '',
        Justification = 'autounattend.xml requires the Administrator password in plain text; the SecureString is decoded once in Main with BSTR zeroing and passed here as the already-decoded value.')]
    param (
        [string]$ComputerName,
        [string]$AdminPasswordPlainText,
        [string]$TimeZone,
        [string]$ImageName,
        [string]$ProductKey,
        [string]$StaticIpAddress,
        [string]$SubnetMask,
        [string]$DefaultGateway,
        [string]$DnsServer,
        [string]$MacAddress
    )

    # XML-escape every dynamic value before it is interpolated into the answer
    # file. SecurityElement.Escape handles &, <, >, " and ' so a password or
    # time zone containing those characters cannot produce malformed XML. The
    # network values are escaped here too (defense in depth); they are already
    # constrained by ValidatePattern on the script's param() block.
    $xmlComputerName    = ConvertTo-XmlText $ComputerName
    $xmlAdminPassword   = ConvertTo-XmlText $AdminPasswordPlainText
    $xmlTimeZone        = ConvertTo-XmlText $TimeZone
    $xmlImageName       = ConvertTo-XmlText $ImageName
    $xmlProductKey      = ConvertTo-XmlText $ProductKey
    $xmlStaticIpAddress = ConvertTo-XmlText $StaticIpAddress
    $xmlDefaultGateway  = ConvertTo-XmlText $DefaultGateway
    $xmlDnsServer       = ConvertTo-XmlText $DnsServer

    $networkXml = ''
    if ($StaticIpAddress) {
        $prefixLength = ConvertTo-CidrPrefixLength -SubnetMask $SubnetMask
        # Bind the IP config to the adapter by MAC; the unattend Identifier
        # expects the format XX-XX-XX-XX-XX-XX (hyphens, uppercase).
        $interfaceIdentifier = $MacAddress.ToUpper().Replace(':', '-')
        $xmlInterfaceIdentifier = ConvertTo-XmlText $interfaceIdentifier
        $routeXml = ''
        if ($DefaultGateway) {
            $routeXml = @"
                    <Routes>
                        <Route wcm:action="add">
                            <Identifier>0</Identifier>
                            <Prefix>0.0.0.0/0</Prefix>
                            <Metric>20</Metric>
                            <NextHopAddress>$xmlDefaultGateway</NextHopAddress>
                        </Route>
                    </Routes>
"@
        }
        $networkXml = @"
        <component name="Microsoft-Windows-TCPIP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <Interfaces>
                <Interface wcm:action="add">
                    <Identifier>$xmlInterfaceIdentifier</Identifier>
                    <Ipv4Settings>
                        <DhcpEnabled>false</DhcpEnabled>
                        <RouterDiscoveryEnabled>false</RouterDiscoveryEnabled>
                    </Ipv4Settings>
                    <UnicastIpAddresses>
                        <IpAddress wcm:action="add" wcm:keyValue="1">$xmlStaticIpAddress/$prefixLength</IpAddress>
                    </UnicastIpAddresses>
                    $routeXml
                </Interface>
            </Interfaces>
        </component>
        <component name="Microsoft-Windows-DNS-Client" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <Interfaces>
                <Interface wcm:action="add">
                    <Identifier>$xmlInterfaceIdentifier</Identifier>
                    <DNSServerSearchOrder>
                        <IpAddress wcm:action="add" wcm:keyValue="1">$xmlDnsServer</IpAddress>
                    </DNSServerSearchOrder>
                    <EnableAdapterDomainNameRegistration>false</EnableAdapterDomainNameRegistration>
                </Interface>
            </Interfaces>
        </component>
"@
    }

    # When -ProductKey is supplied, embed it. When omitted (the default for short-lived
    # test hosts), leave the <ProductKey> element out entirely: evaluation media then
    # installs unattended with no key, while retail/VLSC media shows the product-key page
    # for manual entry instead of failing. Pass -ProductKey to keep retail installs fully
    # unattended.
    if ($ProductKey) {
        $productKeyXml = "<ProductKey><Key>$xmlProductKey</Key></ProductKey>"
    }
    else {
        $productKeyXml = ''
    }

    return @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">

    <settings pass="windowsPE">
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en-US</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UILanguageFallback>en-US</UILanguageFallback>
            <UserLocale>en-US</UserLocale>
        </component>
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <DiskConfiguration>
                <Disk wcm:action="add">
                    <DiskID>0</DiskID>
                    <WillWipeDisk>true</WillWipeDisk>
                    <CreatePartitions>
                        <CreatePartition wcm:action="add">
                            <Order>1</Order>
                            <Type>Primary</Type>
                            <Size>350</Size>
                        </CreatePartition>
                        <CreatePartition wcm:action="add">
                            <Order>2</Order>
                            <Type>Primary</Type>
                            <Extend>true</Extend>
                        </CreatePartition>
                    </CreatePartitions>
                    <ModifyPartitions>
                        <ModifyPartition wcm:action="add">
                            <Order>1</Order>
                            <PartitionID>1</PartitionID>
                            <Label>System Reserved</Label>
                            <Format>NTFS</Format>
                            <Active>true</Active>
                        </ModifyPartition>
                        <ModifyPartition wcm:action="add">
                            <Order>2</Order>
                            <PartitionID>2</PartitionID>
                            <Label>Windows</Label>
                            <Format>NTFS</Format>
                            <Letter>C</Letter>
                        </ModifyPartition>
                    </ModifyPartitions>
                </Disk>
            </DiskConfiguration>
            <ImageInstall>
                <OSImage>
                    <InstallTo>
                        <DiskID>0</DiskID>
                        <PartitionID>2</PartitionID>
                    </InstallTo>
                    <InstallFrom>
                        <MetaData wcm:action="add">
                            <Key>/IMAGE/NAME</Key>
                            <Value>$xmlImageName</Value>
                        </MetaData>
                    </InstallFrom>
                    <WillShowUI>Never</WillShowUI>
                </OSImage>
            </ImageInstall>
            <UserData>
                $productKeyXml
                <AcceptEula>true</AcceptEula>
                <FullName>Administrator</FullName>
                <Organization>Lab</Organization>
            </UserData>
        </component>
    </settings>

    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ComputerName>$xmlComputerName</ComputerName>
            <TimeZone>$xmlTimeZone</TimeZone>
        </component>
        <component name="Microsoft-Windows-TerminalServices-LocalSessionManager" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <fDenyTSConnections>false</fDenyTSConnections>
        </component>
        <component name="Networking-MPSSVC-Svc" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <FirewallGroups>
                <FirewallGroup wcm:action="add" wcm:keyValue="RemoteDesktop">
                    <Active>true</Active>
                    <Group>Remote Desktop</Group>
                    <Profile>all</Profile>
                </FirewallGroup>
            </FirewallGroups>
        </component>
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <Path>cmd /c ipconfig /all &gt; C:\Windows\Temp\netsetup.log</Path>
                    <Description>Capture network configuration for post-deploy diagnostics</Description>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>2</Order>
                    <Path>netsh advfirewall firewall add rule name="Allow ICMPv4-In (Echo Request)" protocol=icmpv4:8,any dir=in action=allow profile=any enable=yes</Path>
                    <Description>Allow inbound ICMPv4 echo request (ping) on all profiles, from any source -- required for Wait-VirtualMachineOnline</Description>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>3</Order>
                    <Path>cmd /c for %d in (D E F G H) do if exist %d:\VMwareToolsUpgrader.exe %d:\setup.exe /S /v"/qn REBOOT=ReallySuppress"</Path>
                    <Description>Silently install VMware Tools from whichever drive letter the tools ISO (sata0:2) was assigned -- VMwareToolsUpgrader.exe identifies the tools ISO since the Windows install ISO also has its own setup.exe at root</Description>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
        $networkXml
    </settings>

    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <ProtectYourPC>3</ProtectYourPC>
            </OOBE>
            <UserAccounts>
                <AdministratorPassword>
                    <Value>$xmlAdminPassword</Value>
                    <PlainText>true</PlainText>
                </AdministratorPassword>
            </UserAccounts>
            <AutoLogon>
                <Enabled>true</Enabled>
                <Username>Administrator</Username>
                <Domain>$xmlComputerName</Domain>
                <LogonCount>1</LogonCount>
                <Password>
                    <Value>$xmlAdminPassword</Value>
                    <PlainText>true</PlainText>
                </Password>
            </AutoLogon>
        </component>
    </settings>

</unattend>
"@
}

function New-AnswerFileIso {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Internal helper; -WhatIf was deliberately removed in v0.1.2 as unimplemented and misleading. Building the ISO is the script purpose.')]
    param (
        [string]$SourceFolderPath,
        [string]$DestinationIsoPath,
        [string]$VolumeName = 'AUTOUNATTEND',
        [string]$LogFilePath
    )

    Write-Log "Creating answer file ISO from: $SourceFolderPath" -LogFilePath $LogFilePath

    # Compile a helper class to read the COM IStream returned by IMAPI2
    $isoHelperSource = @'
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;

public static class IsoStreamHelper {
    public static void WriteToFile(string outputPath, object comStream, int blockSize, long totalBlocks) {
        IStream stream = (IStream)comStream;
        byte[] buffer = new byte[blockSize];
        IntPtr bytesReadPtr = Marshal.AllocHGlobal(Marshal.SizeOf(typeof(int)));
        try {
            using (FileStream fileStream = new FileStream(outputPath, FileMode.Create, FileAccess.Write)) {
                for (long block = 0; block < totalBlocks; block++) {
                    stream.Read(buffer, blockSize, bytesReadPtr);
                    int bytesRead = Marshal.ReadInt32(bytesReadPtr);
                    if (bytesRead == 0) {
                        throw new IOException(string.Format(
                            "IMAPI2 stream ended prematurely at block {0} of {1}.", block, totalBlocks));
                    }
                    fileStream.Write(buffer, 0, bytesRead);
                }
            }
        } finally {
            Marshal.FreeHGlobal(bytesReadPtr);
        }
    }
}
'@
    if (-not ([System.Management.Automation.PSTypeName]'IsoStreamHelper').Type) {
        Add-Type -TypeDefinition $isoHelperSource -Language CSharp
    }

    $fileSystemImage = $null
    $resultImage     = $null
    $imageStream     = $null
    $isoWritten      = $false
    try {
        $fileSystemImage = New-Object -ComObject IMAPI2FS.MsftFileSystemImage
        # ISO9660 (1) + Joliet (2) = 3
        $fileSystemImage.FileSystemsToCreate = 3
        $fileSystemImage.VolumeName = $VolumeName
        $fileSystemImage.Root.AddTree($SourceFolderPath, $false)

        $resultImage = $fileSystemImage.CreateResultImage()
        $imageStream = $resultImage.ImageStream
        [IsoStreamHelper]::WriteToFile(
            $DestinationIsoPath,
            $imageStream,
            $resultImage.BlockSize,
            $resultImage.TotalBlocks
        )
        $isoWritten = $true

        Write-Log "Answer file ISO created: $DestinationIsoPath" -LogFilePath $LogFilePath
    }
    catch {
        # Log then bare re-throw to preserve the original COM exception type/HRESULT/stack
        Write-Log "Failed to create answer file ISO." -LogFilePath $LogFilePath -Level 'ERROR' -ErrorRecord $_
        throw
    }
    finally {
        # Release COM objects children-first (stream and result before the image)
        foreach ($comObject in @($imageStream, $resultImage, $fileSystemImage)) {
            if ($null -ne $comObject) {
                $null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($comObject)
            }
        }
        # Remove any partial ISO if the write did not complete, so a re-run cannot
        # boot from a truncated, password-bearing answer disk.
        if (-not $isoWritten -and (Test-Path $DestinationIsoPath)) {
            Remove-Item -Path $DestinationIsoPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function New-VirtualMachineDisk {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Internal helper; -WhatIf was deliberately removed in v0.1.2 as unimplemented and misleading. Creating the disk is the script purpose.')]
    param (
        [string]$DiskPath,
        [int]$DiskSizeGB,
        [string]$VdiskManagerPath,
        [string]$LogFilePath
    )

    Write-Log "Creating virtual disk: $DiskPath ($DiskSizeGB GB sparse)" -LogFilePath $LogFilePath

    # Invoke-WithRetry re-enters this function on every attempt. Staging the create
    # under a fresh per-attempt GUID and promoting only on success means a failed
    # attempt never occupies $DiskPath, so the next attempt is a clean create instead
    # of an inevitable "already exists" failure. Existing-disk detection is the
    # caller's job (a one-time check before the retry loop, not repeated per attempt).
    $diskDirectory = Split-Path -Path $DiskPath -Parent
    $diskBaseName = [System.IO.Path]::GetFileNameWithoutExtension($DiskPath)
    $stagingPrefix = ".$diskBaseName.creating-$([guid]::NewGuid().ToString('N'))"
    $stagingPath = Join-Path $diskDirectory "$stagingPrefix.vmdk"
    $created = $false

    try {
        # -t 0 = monolithic sparse (grows on demand); -a lsisas1068 = LSI Logic SAS
        # adapter type recorded in the vmdk descriptor (ddb.adapterType). This is
        # descriptor metadata only -- Workstation attaches the resulting vmdk to
        # whatever controller the VMX specifies (nvme0 here), regardless of this value.
        $vdiskOutput = & $VdiskManagerPath `
            '-c' `
            '-s' "${DiskSizeGB}GB" `
            '-a' 'lsisas1068' `
            '-t' '0' `
            $stagingPath 2>&1
        $exitCode = $LASTEXITCODE
        $outputText = ($vdiskOutput | Out-String).Trim()

        if ($exitCode -ne 0) {
            throw "vmware-vdiskmanager.exe failed with exit code $exitCode while creating '$stagingPath'. Output: $outputText"
        }

        # Both paths are in the same directory, so this is a same-volume rename.
        [System.IO.File]::Move($stagingPath, $DiskPath)
        $created = $true
    }
    finally {
        if (-not $created) {
            # The prefix contains a per-attempt GUID; these are the only files this
            # invocation is allowed to remove.
            Get-ChildItem -LiteralPath $diskDirectory -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like "$stagingPrefix*" } |
                Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Log "Virtual disk created." -LogFilePath $LogFilePath
}

function New-VmxConfiguration {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Internal helper; -WhatIf was deliberately removed in v0.1.2 as unimplemented and misleading. Writing the VMX is the script purpose.')]
    param (
        [string]$VmxPath,
        [string]$VmName,
        [string]$VmdkFileName,
        [string]$WindowsIsoPath,
        [string]$AnswerIsoPath,
        [string]$VMwareToolsIsoPath,
        [int]$RamMB,
        [int]$CpuCount,
        [string]$NetworkType,
        [string]$MacAddress,
        [string]$LogFilePath
    )

    Write-Log "Writing VMX configuration: $VmxPath" -LogFilePath $LogFilePath

    $toolsIsoBlock = ''
    if ($VMwareToolsIsoPath) {
        $toolsIsoBlock = @"
sata0:2.present = "TRUE"
sata0:2.deviceType = "cdrom-image"
sata0:2.fileName = "$($VMwareToolsIsoPath.Replace('\','/'))"
sata0:2.startConnected = "TRUE"
"@
    }

    # guestOS: "windows2022srvnext-64" is the VMware Workstation 17.x identifier for WS2025.
    # If the VM shows a guest OS warning, update this value to match your Workstation version.
    $vmxContent = @"
.encoding = "UTF-8"
config.version = "8"
virtualHW.version = "19"
pciBridge0.present = "TRUE"
pciBridge4.present = "TRUE"
pciBridge4.virtualDev = "pcieRootPort"
pciBridge4.functions = "8"
pciBridge5.present = "TRUE"
pciBridge5.virtualDev = "pcieRootPort"
pciBridge5.functions = "8"
pciBridge6.present = "TRUE"
pciBridge6.virtualDev = "pcieRootPort"
pciBridge6.functions = "8"
pciBridge7.present = "TRUE"
pciBridge7.virtualDev = "pcieRootPort"
pciBridge7.functions = "8"
displayName = "$VmName"
guestOS = "windows2022srvnext-64"
firmware = "bios"
numvcpus = "$CpuCount"
cpuid.coresPerSocket = "$CpuCount"
memsize = "$RamMB"
nvme0.present = "TRUE"
nvme0:0.present = "TRUE"
nvme0:0.fileName = "$VmdkFileName"
sata0.present = "TRUE"
sata0:0.present = "TRUE"
sata0:0.deviceType = "cdrom-image"
sata0:0.fileName = "$($WindowsIsoPath.Replace('\','/'))"
sata0:0.startConnected = "TRUE"
sata0:1.present = "TRUE"
sata0:1.deviceType = "cdrom-image"
sata0:1.fileName = "$($AnswerIsoPath.Replace('\','/'))"
sata0:1.startConnected = "TRUE"
$toolsIsoBlock
ethernet0.present = "TRUE"
ethernet0.connectionType = "$NetworkType"
ethernet0.virtualDev = "vmxnet3"
ethernet0.wakeOnPcktRcv = "FALSE"
ethernet0.address = "$MacAddress"
ethernet0.addressType = "static"
usb.present = "TRUE"
ehci.present = "TRUE"
hpet0.present = "TRUE"
vmci0.present = "TRUE"
floppy0.present = "FALSE"
tools.syncTime = "TRUE"
nvram = "$VmName.nvram"
# Disables Spectre/Meltdown-class CPU side-channel mitigations (VMware KB 79832).
# Suppresses the "side channel mitigations enabled" popup and recovers the
# performance hit on Hyper-V/VBS-enabled hosts. Acceptable for short-lived lab
# VMs; reconsider if these VMs ever handle sensitive data on a shared host.
ulm.disableMitigations = "TRUE"
"@

    # VMware's VMX parser mishandles a leading BOM, so write UTF-8 without one
    [System.IO.File]::WriteAllText($VmxPath, $vmxContent, (New-Object System.Text.UTF8Encoding $false))
    Write-Log "VMX configuration written (NIC MAC pinned static: $MacAddress)." -LogFilePath $LogFilePath
}

function Wait-VirtualMachineOnline {
    param (
        [string]$IpAddress,
        [int]$TimeoutMinutes,
        [string]$LogFilePath
    )

    $deadline = (Get-Date).AddMinutes($TimeoutMinutes)
    $pollIntervalSeconds = 20

    Write-Log "Polling $IpAddress every $pollIntervalSeconds seconds (timeout: $TimeoutMinutes min)..." -LogFilePath $LogFilePath

    while ((Get-Date) -lt $deadline) {
        if (Test-Connection -ComputerName $IpAddress -Count 1 -Quiet -ErrorAction SilentlyContinue) {
            Write-Log "VM is online at $IpAddress." -LogFilePath $LogFilePath
            return $true
        }
        $minutesLeft = [math]::Round(($deadline - (Get-Date)).TotalMinutes, 1)
        Write-Log "Not yet online. $minutesLeft min remaining..." -LogFilePath $LogFilePath
        Start-Sleep -Seconds $pollIntervalSeconds
    }

    Write-Log "Timeout reached. VM at $IpAddress did not respond within $TimeoutMinutes minutes." -LogFilePath $LogFilePath -Level 'WARN'
    return $false
}

function Wait-VirtualMachinePoweredOff {
    param (
        [string]$VmrunPath,
        [string]$VmxFilePath,
        [int]$TimeoutMinutes,
        [string]$LogFilePath
    )

    $deadline = (Get-Date).AddMinutes($TimeoutMinutes)
    $pollIntervalSeconds = 10

    Write-Log "Waiting for '$VmxFilePath' to power off (timeout: $TimeoutMinutes min)..." -LogFilePath $LogFilePath

    while ((Get-Date) -lt $deadline) {
        $runningVms = & $VmrunPath -T ws list 2>&1
        if ($LASTEXITCODE -eq 0 -and -not ($runningVms -match [regex]::Escape($VmxFilePath))) {
            Write-Log "VM is powered off." -LogFilePath $LogFilePath
            return $true
        }
        Start-Sleep -Seconds $pollIntervalSeconds
    }

    Write-Log "Timeout reached. '$VmxFilePath' is still running after $TimeoutMinutes minutes." -LogFilePath $LogFilePath -Level 'WARN'
    return $false
}

function Disconnect-VirtualMachineCdRom {
    param (
        [string]$VmrunPath,
        [string]$VmxFilePath,
        [string]$DeviceName,
        [string]$LogFilePath
    )

    $disconnectOutput = & $VmrunPath -T ws disconnectNamedDevice $VmxFilePath $DeviceName 2>&1
    if ($LASTEXITCODE -ne 0 -or ($disconnectOutput -match 'Error')) {
        Write-Log "Could not eject CD/DVD device '$DeviceName' (exit code $LASTEXITCODE): $disconnectOutput -- eject manually in VMware Workstation if needed." -LogFilePath $LogFilePath -Level 'WARN'
    }
    else {
        Write-Log "Ejected CD/DVD device '$DeviceName'." -LogFilePath $LogFilePath
    }
}

function Remove-VirtualDvdDrivesFromVmx {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Internal helper; -WhatIf was deliberately removed in v0.1.2 as unimplemented and misleading. Editing the VMX is the script purpose.')]
    param (
        [string]$VmxFilePath,
        [string[]]$DeviceNames,
        [string]$LogFilePath
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $vmxLines  = [System.IO.File]::ReadAllText($VmxFilePath, $utf8NoBom) -split "`r?`n"

    $remainingLines = $vmxLines | Where-Object {
        $line = $_
        -not ($DeviceNames | Where-Object { $line -match "^\s*$([regex]::Escape($_))\." })
    }

    # VMware's VMX parser mishandles a leading BOM, so write UTF-8 without one. The caller
    # invokes this ONLY after confirming the VM is powered off, which is what makes the edit
    # stick: while vmware-vmx.exe is alive it owns the VMX and rewrites it from its
    # in-memory device list at power-off, silently discarding anything written during the
    # session. The caller restarts the VM immediately after this returns, so the removal is
    # visible on that restart.
    [System.IO.File]::WriteAllText($VmxFilePath, ($remainingLines -join "`r`n"), $utf8NoBom)

    foreach ($deviceName in $DeviceNames) {
        Write-Log "Removed CD/DVD drive '$deviceName' from the VMX while the VM is powered off; effective on the restart that follows." -LogFilePath $LogFilePath
    }
}

#endregion Functions

#region Variables

$runTimestamp       = Get-Date -Format 'yyyyMMdd_HHmmss'
$vmDirectory        = Join-Path $VmStoragePath $VmName
$vmxFilePath        = Join-Path $vmDirectory "$VmName.vmx"
$vmdkFilePath       = Join-Path $vmDirectory "$VmName.vmdk"
$logFilePath        = Join-Path $LogPath "VMDeploy_$runTimestamp.csv"
$transcriptFilePath = Join-Path $LogPath "VMDeploy_${runTimestamp}_Transcript.txt"
$answerTempDir      = Join-Path $TempPath 'autounattend'
$answerXmlPath      = Join-Path $answerTempDir 'autounattend.xml'
$answerIsoPath      = Join-Path $TempPath 'autounattend.iso'
$vmMacAddress       = New-VMwareMacAddress

# WS2025 WIM edition names (Desktop Experience), selected via /IMAGE/NAME -- stable across
# media regardless of how install.wim was assembled.
# IMPORTANT: these strings MUST be set to match the edition names in YOUR media EXACTLY
# (bracketing and casing included). If they do not match, Windows Setup falls back to
# image index 1 (Server Core) and unattended setup fails with "Setup has failed to
# validate the product key" rather than prompting interactively. Obtain the exact names
# for the target media and update the two values below if they differ:
#   Get-WindowsImage -ImagePath <mounted-ISO-drive>:\sources\install.wim
# On evaluation media (sources\ei.cfg contains "[Channel]" "eval"), the names include
# "Evaluation", e.g. "Windows Server 2025 Standard Evaluation (Desktop Experience)" --
# confirmed against a SERVER_EVAL_x64FRE ISO. On VL/retail media the names typically
# omit "Evaluation"; re-verify if you switch media.
$imageName = switch ($Edition) {
    'Standard'   { 'Windows Server 2025 Standard Evaluation (Desktop Experience)' }
    'Datacenter' { 'Windows Server 2025 Datacenter Evaluation (Desktop Experience)' }
}

#endregion Variables

#region Main

$adminPasswordPlain = $null
$transcriptStarted  = $false
$logInitialized     = $false

try {
    Initialize-Log -LogFilePath $logFilePath
    $logInitialized = $true

    try {
        $null = Start-Transcript -Path $transcriptFilePath -Force -ErrorAction Stop
        $transcriptStarted = $true
        Write-Log "Transcript started: $transcriptFilePath" -LogFilePath $logFilePath
    }
    catch {
        Write-Log "Could not start transcript at '$transcriptFilePath'." -LogFilePath $logFilePath -Level 'WARN' -ErrorRecord $_
    }

    foreach ($directory in @($TempPath, $answerTempDir, $vmDirectory)) {
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $directory -Force -ErrorAction Stop
        }
    }

    Write-Log "=== VMware Workstation Unattended Deploy: $VmName ===" -LogFilePath $logFilePath
    Write-Log "ISO: $IsoPath | Edition: $Edition (image '$imageName') | RAM: $RamMB MB | CPU: $CpuCount | Disk: $DiskGB GB" -LogFilePath $logFilePath

    if (Test-Path $vmxFilePath) {
        throw "VMX file already exists at '$vmxFilePath'. Remove the existing VM or choose a different -VmName."
    }

    $vmrunPath        = Find-VMwareExecutable -ExecutableName 'vmrun.exe'              -LogFilePath $logFilePath
    $vdiskManagerPath = Find-VMwareExecutable -ExecutableName 'vmware-vdiskmanager.exe' -LogFilePath $logFilePath

    $vmwareInstallDir  = Split-Path $vmrunPath -Parent
    $vmwareToolsIsoPath = Join-Path $vmwareInstallDir 'windows.iso'
    if (-not (Test-Path $vmwareToolsIsoPath)) {
        Write-Log "VMware Tools ISO (windows.iso) not found alongside vmrun.exe. Proceeding without it." -LogFilePath $logFilePath -Level 'WARN'
        $vmwareToolsIsoPath = $null
    }
    else {
        Write-Log "VMware Tools ISO found: $vmwareToolsIsoPath" -LogFilePath $logFilePath
    }

    # Decode SecureString for embedding in answer file; BSTR zeroed in finally to cover exception path
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword)
    try {
        $adminPasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }

    Write-Log "Generating autounattend.xml..." -LogFilePath $logFilePath
    $xmlContent = New-AutoUnattendXml `
        -ComputerName         $ComputerName `
        -AdminPasswordPlainText $adminPasswordPlain `
        -TimeZone             $TimeZone `
        -ImageName            $imageName `
        -ProductKey           $ProductKey `
        -StaticIpAddress      $StaticIpAddress `
        -SubnetMask           $SubnetMask `
        -DefaultGateway       $DefaultGateway `
        -DnsServer            $DnsServer `
        -MacAddress           $vmMacAddress

    # Write without a BOM (consistent with the VMX); the XML prolog already declares UTF-8
    [System.IO.File]::WriteAllText($answerXmlPath, $xmlContent, (New-Object System.Text.UTF8Encoding $false))
    # Drop the in-memory copy of the answer file; it holds the password in plain text.
    # Note: .NET strings are immutable so this cannot zero the bytes -- it only makes the
    # copy GC-eligible sooner. True erasure of the managed copy is not possible here.
    $xmlContent = $null
    Write-Log "autounattend.xml written to: $answerXmlPath" -LogFilePath $logFilePath

    New-AnswerFileIso `
        -SourceFolderPath   $answerTempDir `
        -DestinationIsoPath $answerIsoPath `
        -LogFilePath        $logFilePath

    # Remove plain-text answer file now that the ISO is built
    try {
        Remove-Item -Path $answerXmlPath -Force -ErrorAction Stop
        Write-Log "Plain-text answer file removed from disk." -LogFilePath $logFilePath
    }
    catch {
        Write-Log "Failed to remove plain-text answer file '$answerXmlPath' -- delete manually." -LogFilePath $logFilePath -Level 'WARN'
    }

    if (Test-Path -LiteralPath $vmdkFilePath) {
        throw "Refusing to overwrite existing virtual disk '$vmdkFilePath'."
    }

    Invoke-WithRetry -OperationName 'Create virtual disk' -LogFilePath $logFilePath -Operation {
        New-VirtualMachineDisk `
            -DiskPath        $vmdkFilePath `
            -DiskSizeGB      $DiskGB `
            -VdiskManagerPath $vdiskManagerPath `
            -LogFilePath     $logFilePath
    }

    New-VmxConfiguration `
        -VmxPath            $vmxFilePath `
        -VmName             $VmName `
        -VmdkFileName       "$VmName.vmdk" `
        -WindowsIsoPath     $IsoPath `
        -AnswerIsoPath      $answerIsoPath `
        -VMwareToolsIsoPath $vmwareToolsIsoPath `
        -RamMB              $RamMB `
        -CpuCount           $CpuCount `
        -NetworkType        $NetworkType `
        -MacAddress         $vmMacAddress `
        -LogFilePath        $logFilePath

    $vmrunStartArgs = [System.Collections.Generic.List[string]]@('-T', 'ws', 'start', $vmxFilePath)
    if (-not $ShowConsole) { $vmrunStartArgs.Add('nogui') }
    Write-Log "Starting VM (mode: $(if ($ShowConsole) { 'console' } else { 'headless' }))..." -LogFilePath $logFilePath
    Invoke-WithRetry -OperationName 'vmrun start' -LogFilePath $logFilePath -Operation {
        $startOutput = & $vmrunPath @vmrunStartArgs 2>&1
        if ($LASTEXITCODE -ne 0 -or ($startOutput -match 'Error')) {
            throw "vmrun start failed (exit code $LASTEXITCODE): $startOutput"
        }
    }
    Write-Log "VM started. Windows installation is in progress." -LogFilePath $logFilePath

    try {
        $vmwareGuiPath = Find-VMwareExecutable -ExecutableName 'vmware.exe' -LogFilePath $logFilePath
        Start-Process -FilePath $vmwareGuiPath -ArgumentList @($vmxFilePath) -ErrorAction Stop
        Write-Log "Opened '$VmName' in the VMware Workstation Library." -LogFilePath $logFilePath
    }
    catch {
        Write-Log "Could not open '$VmName' in the VMware Workstation GUI -- open it manually if it does not appear in the Library." -LogFilePath $logFilePath -Level 'WARN' -ErrorRecord $_
    }

    if ($StaticIpAddress) {
        $isOnline = Wait-VirtualMachineOnline `
            -IpAddress      $StaticIpAddress `
            -TimeoutMinutes $TimeoutMinutes `
            -LogFilePath    $logFilePath

        if ($isOnline) {
            Write-Log "VM is online. Waiting $PostSetupDelayMinutes more minute(s) for Windows Setup specialize and the VMware Tools install to finish before ejecting installation media..." -LogFilePath $logFilePath
            Start-Sleep -Seconds ($PostSetupDelayMinutes * 60)

            Disconnect-VirtualMachineCdRom -VmrunPath $vmrunPath -VmxFilePath $vmxFilePath -DeviceName 'sata0:0' -LogFilePath $logFilePath
            Disconnect-VirtualMachineCdRom -VmrunPath $vmrunPath -VmxFilePath $vmxFilePath -DeviceName 'sata0:1' -LogFilePath $logFilePath
            $cdromDevicesToRemove = @('sata0:0', 'sata0:1')
            if ($vmwareToolsIsoPath) {
                Disconnect-VirtualMachineCdRom -VmrunPath $vmrunPath -VmxFilePath $vmxFilePath -DeviceName 'sata0:2' -LogFilePath $logFilePath
                $cdromDevicesToRemove += 'sata0:2'
            }

            # Removing the CD/DVD drive entries from the VMX only persists if no
            # vmware-vmx.exe process is running for this VM -- otherwise VMware rewrites
            # the VMX from its in-memory device list (which still has them) at power-off,
            # silently undoing the edit. So: soft-stop, edit while powered off, restart.
            $vmPoweredOff = $false
            Write-Log "Stopping '$VmName' (soft) to remove CD/DVD drive definitions from the VMX..." -LogFilePath $logFilePath
            $stopOutput = & $vmrunPath -T ws stop $vmxFilePath soft 2>&1
            if ($LASTEXITCODE -ne 0 -or ($stopOutput -match 'Error')) {
                Write-Log "vmrun stop failed (exit code $LASTEXITCODE): $stopOutput -- CD/DVD drives were not removed; they remain ejected but defined in VM Settings." -LogFilePath $logFilePath -Level 'WARN'
            }
            else {
                $vmPoweredOff = Wait-VirtualMachinePoweredOff -VmrunPath $vmrunPath -VmxFilePath $vmxFilePath -TimeoutMinutes $ShutdownTimeoutMinutes -LogFilePath $logFilePath
                if (-not $vmPoweredOff) {
                    Write-Log "CD/DVD drives were not removed; check VMware Workstation, the VM may still be shutting down." -LogFilePath $logFilePath -Level 'WARN'
                }
            }

            if ($vmPoweredOff) {
                try {
                    Remove-VirtualDvdDrivesFromVmx -VmxFilePath $vmxFilePath -DeviceNames $cdromDevicesToRemove -LogFilePath $logFilePath
                }
                catch {
                    Write-Log "Could not remove CD/DVD drive entries from '$vmxFilePath' -- they will remain after restart." -LogFilePath $logFilePath -Level 'WARN' -ErrorRecord $_
                }

                # The VM is powered off at this point regardless of whether the edit above
                # succeeded -- always restart it, since leaving it off is a worse outcome
                # than leaving the CD/DVD drives in place.
                Write-Log "Restarting '$VmName'..." -LogFilePath $logFilePath
                try {
                    Invoke-WithRetry -OperationName 'vmrun start (post-removal restart)' -LogFilePath $logFilePath -Operation {
                        $startOutput = & $vmrunPath @vmrunStartArgs 2>&1
                        if ($LASTEXITCODE -ne 0 -or ($startOutput -match 'Error')) {
                            throw "vmrun start failed (exit code $LASTEXITCODE): $startOutput"
                        }
                    }
                }
                catch {
                    $manualStartCmd = "& `"$vmrunPath`" -T ws start `"$vmxFilePath`"" + $(if (-not $ShowConsole) { ' nogui' })
                    Write-Log "'$VmName' is POWERED OFF and failed to restart after CD/DVD drive removal -- start it manually: $manualStartCmd" -LogFilePath $logFilePath -Level 'ERROR' -ErrorRecord $_
                    throw
                }

                $isOnlineAfterRestart = Wait-VirtualMachineOnline -IpAddress $StaticIpAddress -TimeoutMinutes $RestartTimeoutMinutes -LogFilePath $logFilePath
                if ($isOnlineAfterRestart) {
                    Write-Log "Deployment complete. '$VmName' is online at $StaticIpAddress with no CD/DVD drives attached." -LogFilePath $logFilePath
                }
                else {
                    Write-Log "'$VmName' restarted but did not respond within $RestartTimeoutMinutes minute(s) -- verify manually in VMware Workstation." -LogFilePath $logFilePath -Level 'WARN'
                }
            }
            else {
                Write-Log "Deployment complete. '$VmName' is online at $StaticIpAddress (CD/DVD drives ejected but still defined in VM Settings)." -LogFilePath $logFilePath
            }
        }
        else {
            Write-Log "VM started but did not respond within the timeout. Verify in VMware Workstation. Installation media was not ejected." -LogFilePath $logFilePath -Level 'WARN'
        }
    }
    else {
        Write-Log "No -StaticIpAddress specified; DHCP in use. Installation typically takes less than 15 minutes. Monitor in VMware Workstation." -LogFilePath $logFilePath
    }

    Write-Log "VMX: $vmxFilePath" -LogFilePath $logFilePath
    Write-Log "Log: $logFilePath" -LogFilePath $logFilePath
}
catch {
    if ($logInitialized) {
        try {
            Write-Log -Message "Deployment failed." -LogFilePath $logFilePath -Level 'ERROR' -ErrorRecord $_
        }
        catch {
            [Console]::Error.WriteLine(
                "Deployment failed, and the log could not be updated: $($_.Exception.Message)")
        }
    }
    else {
        [Console]::Error.WriteLine(
            "Deployment failed before logging was initialized: $($_.Exception.Message)")
    }
    throw
}
finally {
    # .NET strings are immutable; this drops the reference but cannot zero the bytes
    # of the decoded password. The BSTR copy was already zeroed via ZeroFreeBSTR above.
    $adminPasswordPlain = $null

    # The answer ISO embeds the Administrator password in plain text. It is locked by
    # VMware while sata0:1 is connected, so deletion only succeeds once the VM came
    # online and the eject above released the lock; if not, it is still mounted and
    # this Remove-Item attempt will fail (e.g. -StaticIpAddress not used, the online
    # check timed out, or the eject itself failed) -- only warn in that case.
    if (Test-Path $answerIsoPath) {
        try {
            Remove-Item -Path $answerIsoPath -Force -ErrorAction Stop
            Write-Log "Answer file ISO deleted: $answerIsoPath" -LogFilePath $logFilePath
        }
        catch {
            Write-Log "Could not delete answer file ISO '$answerIsoPath' (likely still mounted by the VM)." -LogFilePath $logFilePath -Level 'WARN' -ErrorRecord $_
        }

        if (Test-Path $answerIsoPath) {
            Write-Log ("Answer file ISO retained at '$answerIsoPath'. It contains the Administrator " +
                "password in plain text -- delete it manually once the VM no longer has it mounted.") `
                -LogFilePath $logFilePath -Level 'WARN'
        }
    }

    if ($transcriptStarted) {
        try {
            $null = Stop-Transcript
        }
        catch {
            Write-Log "Could not stop transcript." -LogFilePath $logFilePath -Level 'WARN' -ErrorRecord $_
        }
    }
}

#endregion Main
