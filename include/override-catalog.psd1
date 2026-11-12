@{
    # The settings New-VMwareWorkstationVM.ps1 reads from overrides\overrides.psd1.
    # OVERRIDE.md is generated from this file, so a change here is followed by a fresh
    # OVERRIDE.md. The offline suite checks both against the script.
    Project  = 'New-VMwareWorkstationVM'
    Settings = @{
        ComputerName = @{
            Target        = 'Parameter'
            Name          = 'ComputerName'
            Shipped       = 'WIN2025'
            ShippedReason = 'A short name that says what the VM runs and fits the 15-character NetBIOS limit'
            OverrideNote  = 'build-lab passes it, so in a build-lab run set it in build-lab''s file'
        }
        CpuCount = @{
            Target        = 'Parameter'
            Name          = 'CpuCount'
            Shipped       = 2
            ShippedReason = 'Enough for Windows Setup and a lab role without crowding the host'
            OverrideNote  = 'build-lab passes it, so in a build-lab run set it in build-lab''s file'
        }
        DefaultGateway = @{
            Target        = 'Parameter'
            Name          = 'DefaultGateway'
            ShippedText   = 'None'
            ShippedReason = 'The gateway differs per host and network, so the script can''t guess one'
            OverrideNote  = 'build-lab passes it when it has one, and then build-lab''s value is used'
        }
        DiskGB = @{
            Target        = 'Parameter'
            Name          = 'DiskGB'
            Shipped       = 60
            ShippedReason = 'Room for Windows Server 2025 with Desktop Experience and a lab role, on a sparse disk that grows only as it fills'
            OverrideNote  = 'build-lab passes it, so in a build-lab run set it in build-lab''s file'
        }
        DnsServer = @{
            Target        = 'Parameter'
            Name          = 'DnsServer'
            Shipped       = '8.8.8.8'
            ShippedReason = 'A public resolver that answers from any network the VM lands on'
            OverrideNote  = 'build-lab passes it, so in a build-lab run set it in build-lab''s file'
        }
        Edition = @{
            Target        = 'Parameter'
            Name          = 'Edition'
            Shipped       = 'Standard'
            ShippedReason = 'The edition most lab roles need'
        }
        GuestOS = @{
            Target        = 'Constant'
            Name          = 'guestOS'
            Shipped       = 'windows2022srvnext-64'
            Summary       = 'The VMX guestOS value, the guest operating system type Workstation shows for the VM'
            ShippedReason = 'The VMware Workstation 17 identifier for Windows Server 2025'
            ValuesNote    = 'Set it to the identifier your Workstation version uses when the VM shows a guest OS warning'
            Rule          = @{ Type = 'String'; Pattern = '\A[A-Za-z0-9-]{1,64}\z'; Description = '1 to 64 letters, digits or hyphens' }
        }
        ImageNameDatacenter = @{
            Target        = 'Constant'
            Name          = 'imageNameDatacenter'
            Shipped       = 'Windows Server 2025 Datacenter Evaluation (Desktop Experience)'
            Summary       = 'The install image name Windows Setup uses when the edition is Datacenter'
            ShippedReason = 'The Desktop Experience image name on Windows Server 2025 evaluation media'
            ValuesNote    = 'It must match an image name in the ISO''s install.wim exactly. The README''s Image Name Verification shows how to read them'
            Rule          = @{ Type = 'String'; Pattern = '\A[^\x00-\x1F\x7F]{1,256}\z'; Description = '1 to 256 characters on one line' }
        }
        ImageNameStandard = @{
            Target        = 'Constant'
            Name          = 'imageNameStandard'
            Shipped       = 'Windows Server 2025 Standard Evaluation (Desktop Experience)'
            Summary       = 'The install image name Windows Setup uses when the edition is Standard'
            ShippedReason = 'The Desktop Experience image name on Windows Server 2025 evaluation media'
            ValuesNote    = 'It must match an image name in the ISO''s install.wim exactly. The README''s Image Name Verification shows how to read them'
            Rule          = @{ Type = 'String'; Pattern = '\A[^\x00-\x1F\x7F]{1,256}\z'; Description = '1 to 256 characters on one line' }
        }
        InputLocale = @{
            Target        = 'Constant'
            Name          = 'inputLocale'
            Shipped       = 'en-US'
            Summary       = 'The answer file''s InputLocale, the input language and keyboard layout'
            ShippedReason = 'The language of the evaluation media this project targets'
            Rule          = @{
                Type        = 'String'
                Pattern     = '\A\s*(?:[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*|[0-9A-Fa-f]{4}:[0-9A-Fa-f]{8})(?:\s*;\s*(?:[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*|[0-9A-Fa-f]{4}:[0-9A-Fa-f]{8}))*\s*\z'
                Description = 'a language name such as `en-GB` in any letter case, a locale ID and keyboard layout such as `0409:00000409`, or several of those separated by semicolons, the first being the default'
            }
        }
        LogPath = @{
            Target        = 'Parameter'
            Name          = 'LogPath'
            ShippedText   = 'The `logs` folder beside the script'
            ShippedReason = 'The logs stay with the copy of the script that wrote them, wherever it was started from'
            OverrideNote  = 'build-lab passes its own log folder, so in a build-lab run this key isn''t used'
            ValuesNote    = 'A relative path in the override file resolves from the script''s folder'
            Rule          = @{ Type = 'String'; MinLength = 1; Description = 'a folder path' }
        }
        NetworkType = @{
            Target        = 'Parameter'
            Name          = 'NetworkType'
            Shipped       = 'nat'
            ShippedReason = 'NAT gives the VM internet access through the host with no change to the host''s own network'
            OverrideNote  = 'build-lab passes it, so in a build-lab run set it in build-lab''s file'
        }
        Organization = @{
            Target        = 'Constant'
            Name          = 'organization'
            Shipped       = 'Lab'
            Summary       = 'The answer file''s Organization, the name of the organization that owns the computer'
            ShippedReason = 'A neutral name for a lab machine'
            Rule          = @{ Type = 'String'; Pattern = '\A[^\x00-\x1F\x7F]{1,63}\z'; Description = '1 to 63 characters on one line, the limit Microsoft documents for this answer file setting' }
        }
        PostSetupDelayMinutes = @{
            Target        = 'Parameter'
            Name          = 'PostSetupDelayMinutes'
            Shipped       = 5
            ShippedReason = 'A ping reply can come before the specialize pass and the VMware Tools install finish, so the script waits before it ejects the media'
        }
        ProductKey = @{
            Target        = 'Parameter'
            Name          = 'ProductKey'
            Secret        = $true
            ShippedText   = 'None'
            ShippedReason = 'Evaluation media installs with no key. Retail and volume license media need one to stay unattended'
        }
        RamMB = @{
            Target        = 'Parameter'
            Name          = 'RamMB'
            Shipped       = 4096
            ShippedReason = 'Comfortable for Windows Server 2025 with Desktop Experience in a lab, and small enough for most hosts'
            OverrideNote  = 'build-lab passes it, so in a build-lab run set it in build-lab''s file'
        }
        RestartTimeoutMinutes = @{
            Target        = 'Parameter'
            Name          = 'RestartTimeoutMinutes'
            Shipped       = 10
            ShippedReason = 'The restart after the drive removal is a plain reboot, much faster than Setup'
        }
        ShowConsole = @{
            Target        = 'Parameter'
            Name          = 'ShowConsole'
            Shipped       = $false
            ShippedReason = 'A headless run puts no console window in front of you, and the VM still opens in the Workstation library'
            Rule          = @{ Type = 'Boolean' }
        }
        ShutdownTimeoutMinutes = @{
            Target        = 'Parameter'
            Name          = 'ShutdownTimeoutMinutes'
            Shipped       = 5
            ShippedReason = 'Long enough for a soft shutdown of a freshly installed server'
        }
        SubnetMask = @{
            Target        = 'Parameter'
            Name          = 'SubnetMask'
            Shipped       = '255.255.255.0'
            ShippedReason = 'Workstation allocates its NAT network as a /24'
            OverrideNote  = 'build-lab passes it, so in a build-lab run set it in build-lab''s file'
        }
        SystemLocale = @{
            Target        = 'Constant'
            Name          = 'systemLocale'
            Shipped       = 'en-US'
            Summary       = 'The answer file''s SystemLocale, the default language for non-Unicode programs'
            ShippedReason = 'The language of the evaluation media this project targets'
            Rule          = @{ Type = 'String'; Pattern = '\A[A-Za-z]{2,3}(-[A-Za-z0-9]{2,8})*\z'; Description = 'a culture name such as `en-GB`, in any letter case' }
        }
        TempPath = @{
            Target        = 'Parameter'
            Name          = 'TempPath'
            ShippedText   = '`%TEMP%\VMDeploy`'
            ShippedReason = 'A per-user scratch folder the script can always write to'
            OverrideNote  = 'build-lab passes a folder per build, so in a build-lab run this key isn''t used'
            ValuesNote    = 'A relative path in the override file resolves from the script''s folder'
            Rule          = @{ Type = 'String'; MinLength = 1; Description = 'a folder path' }
        }
        TimeoutMinutes = @{
            Target        = 'Parameter'
            Name          = 'TimeoutMinutes'
            Shipped       = 90
            ShippedReason = 'Covers a full unattended install on a slow host with room to spare'
            OverrideNote  = 'build-lab passes it, so in a build-lab run set it in build-lab''s file'
        }
        TimeZone = @{
            Target        = 'Parameter'
            Name          = 'TimeZone'
            Shipped       = 'Pacific Standard Time'
            ShippedReason = 'The author''s time zone'
            Rule          = @{ Type = 'String'; MinLength = 1; Description = 'a Windows time zone ID, as `tzutil /l` lists them' }
        }
        UserLocale = @{
            Target        = 'Constant'
            Name          = 'userLocale'
            Shipped       = 'en-US'
            Summary       = 'The answer file''s UserLocale, the formats for dates, times, currency and numbers'
            ShippedReason = 'The language of the evaluation media this project targets'
            Rule          = @{ Type = 'String'; Pattern = '\A[A-Za-z]{2,3}(-[A-Za-z0-9]{2,8})*\z'; Description = 'a culture name such as `en-GB`, in any letter case' }
        }
        VmName = @{
            Target        = 'Parameter'
            Name          = 'VmName'
            Shipped       = 'WS2025-Server'
            ShippedReason = 'Names the operating system the VM runs'
            OverrideNote  = 'build-lab passes it, so in a build-lab run set it in build-lab''s file'
        }
    }
    Siblings = @{
        'build-lab'    = @('AdDomainSourcePath', 'DeploymentTimeoutMinutes', 'DomainJoinTimeoutMinutes', 'EnableEventLogging', 'GuestReadyTimeoutMinutes', 'MaxMemberServerCount', 'MemberCpuCount', 'MemberDiskGB', 'MemberRamMB', 'MemberServerCount', 'VmBuilderScriptPath')
        'new-AdDomain' = @('CaCommonName', 'CaDatabasePath', 'CaHashAlgorithm', 'CaKeyLength', 'CaLogPath', 'CaValidityYears', 'ComputerCount', 'DnsForwarders', 'DomainMode', 'DomainName', 'DsrmPassword', 'ForestMode', 'GroupCount', 'LaptopPrefix', 'LockoutDurationMinutes', 'LockoutThreshold', 'MaxCompanyCount', 'MaxDA', 'MaxGroupMembers', 'MaxGroupNestingDepth', 'MaxPasswordAgeDays', 'MinCompanyCount', 'MinDA', 'MinGroupMembers', 'MinPasswordLength', 'NetBIOSName', 'NtpServers', 'PasswordHistoryCount', 'PasswordLength', 'PctDisabled', 'PctLocked', 'PctPwExpired', 'PctPwNeverExpires', 'PctRemoteUsers', 'PctSmartcard', 'PrimarySiteName', 'PrimarySubnet', 'RandomSeed', 'RequiredOSBuild', 'ServerPrefix', 'UpnPattern', 'UserCount', 'WorkstationPrefix')
    }
    Document = @{
        NotCovered = @(
            @{ Name = 'AdminPassword'; Reason = 'A credential, and mandatory, so it is passed for each run and never stored as a setting' }
            @{ Name = 'IsoPath'; Reason = 'Mandatory, and the ISO is chosen for each run' }
            @{ Name = 'StaticIpAddress'; Reason = 'Each VM needs its own address' }
            @{ Name = 'UILanguage'; Reason = 'It must match the language of the media, which is en-US on the evaluation media this project targets' }
            @{ Name = 'UILanguageFallback'; Reason = 'It must match the language of the media, which is en-US on the evaluation media this project targets' }
            @{ Name = 'VmStoragePath'; Reason = 'Mandatory, and where each VM goes is chosen for each run' }
            @{ Name = 'VMware Workstation install folder'; Reason = 'The script searches the two standard Program Files folders. A Workstation installed elsewhere needs a script change' }
            @{ Name = 'virtualHW.version'; Reason = 'Tied to the NVMe and PCIe layout the VMX was tested with' }
        )
        Security = @(
            'A product key set here is written into the answer file and its ISO, as one passed on the command line is'
        )
    }
}
