# Example override file for New-VMwareWorkstationVM. Each release generates it from
# include\override-catalog.psd1 and replaces it, so don't edit it here.
#
# No run reads this file. To use it, copy the lines you need into the @{ } of
# overrides\overrides.psd1 in the project folder, or copy this whole file there.
# Then remove the # in front of each setting you want to change and set your value.
# Leave the others commented out, because a setting you uncomment counts as one you
# chose, even at its shipped value. A setting left commented out keeps its shipped
# value, and follows that value when a later release changes it.
#
# Every value shown is the shipped one, so a copy left as it is changes nothing.
# A setting shown with no value has no default that can be written here. Give it
# a value before you remove its #, or the run stops.
#
# OVERRIDE.md lists the values each setting accepts, why it ships as it does, and
# what else can set it. Save the file as UTF-8 with a BOM if you add non-ASCII text.

@{
    # The Windows computer name the VM gets.
    # ComputerName = 'WIN2025'

    # How many virtual CPUs the VM gets.
    # CpuCount = 2

    # The default gateway that goes with a static IP address.
    # Shipped default, in words. None.
    # DefaultGateway =

    # The size of the operating system disk, in GB.
    # DiskGB = 60

    # The DNS server that goes with a static IP address.
    # DnsServer = '8.8.8.8'

    # The Windows Server edition that Windows Setup installs.
    # Edition = 'Standard'

    # The VMX guestOS value, the guest operating system type Workstation shows for the VM.
    # GuestOS = 'windows2022srvnext-64'

    # The install image name Windows Setup uses when the edition is Datacenter.
    # ImageNameDatacenter = 'Windows Server 2025 Datacenter Evaluation (Desktop Experience)'

    # The install image name Windows Setup uses when the edition is Standard.
    # ImageNameStandard = 'Windows Server 2025 Standard Evaluation (Desktop Experience)'

    # The answer file's InputLocale, the input language and keyboard layout.
    # InputLocale = 'en-US'

    # The folder for the CSV log and the full transcript.
    # Shipped default, in words. The logs folder beside the script.
    # LogPath =

    # The kind of Workstation network the VM's adapter connects to.
    # NetworkType = 'nat'

    # The answer file's Organization, the name of the organization that owns the computer.
    # Organization = 'Lab'

    # How long to wait after the first ping reply before the media is ejected, in minutes.
    # PostSetupDelayMinutes = 5

    # The product key for retail or volume license media.
    # Secret. Its shipped value is never shown.
    # ProductKey =

    # The memory the VM gets, in MB.
    # RamMB = 4096

    # The longest wait for the VM to come back online after the drive removal, in minutes.
    # RestartTimeoutMinutes = 10

    # Whether the run shows the Workstation console window instead of running headless.
    # ShowConsole = $false

    # The longest wait for the soft shutdown before the drive removal, in minutes.
    # ShutdownTimeoutMinutes = 5

    # The subnet mask that goes with a static IP address.
    # SubnetMask = '255.255.255.0'

    # The answer file's SystemLocale, the default language for non-Unicode programs.
    # SystemLocale = 'en-US'

    # The scratch folder for the answer XML and the bootable answer ISO.
    # Shipped default, in words. %TEMP%\VMDeploy.
    # TempPath =

    # The Windows time zone the guest is set to.
    # TimeZone = 'Pacific Standard Time'

    # The longest wait for the VM to come online after it starts, in minutes.
    # TimeoutMinutes = 90

    # The answer file's UserLocale, the formats for dates, times, currency and numbers.
    # UserLocale = 'en-US'

    # The VM folder, VMX and VMDK name, and the name Workstation shows for the VM.
    # VmName = 'WS2025-Server'
}
