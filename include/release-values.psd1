@{
    FormatVersion = 1
    Project = 'New-VMwareWorkstationVM'
    Releases = @{
        '1.0' = @{
            Tag = 'v1.0'
            HeaderVersion = '1.0.0'
            Settings = @{
                ComputerName = @{ Constant = 'WIN2025' }
                CpuCount = @{ Constant = 2 }
                DefaultGateway = @{ NoDefault = $true }
                DiskGB = @{ Constant = 60 }
                DnsServer = @{ Constant = '8.8.8.8' }
                Edition = @{ Constant = 'Standard' }
                GuestOS = @{ Constant = 'windows2022srvnext-64' }
                ImageNameDatacenter = @{ Constant = 'Windows Server 2025 Datacenter Evaluation (Desktop Experience)' }
                ImageNameStandard = @{ Constant = 'Windows Server 2025 Standard Evaluation (Desktop Experience)' }
                InputLocale = @{ Constant = 'en-US' }
                LogPath = @{ Expression = '"$(if ($PSScriptRoot) { Join-Path $PSScriptRoot ''logs'' } else { ''.\logs'' })"' }
                NetworkType = @{ Constant = 'nat' }
                Organization = @{ Constant = 'Lab' }
                PostSetupDelayMinutes = @{ Constant = 5 }
                ProductKey = @{ NoDefault = $true }
                RamMB = @{ Constant = 4096 }
                RestartTimeoutMinutes = @{ Constant = 10 }
                ShowConsole = @{ NoDefault = $true }
                ShutdownTimeoutMinutes = @{ Constant = 5 }
                SubnetMask = @{ Constant = '255.255.255.0' }
                SystemLocale = @{ Constant = 'en-US' }
                TempPath = @{ Expression = '"$env:TEMP\VMDeploy"' }
                TimeZone = @{ Constant = 'Pacific Standard Time' }
                TimeoutMinutes = @{ Constant = 90 }
                UserLocale = @{ Constant = 'en-US' }
                VmName = @{ Constant = 'WS2025-Server' }
            }
        }
        '1.0.1' = @{
            Tag = 'v1.0.1'
            HeaderVersion = '1.0.0'
            Settings = @{
                ComputerName = @{ Constant = 'WIN2025' }
                CpuCount = @{ Constant = 2 }
                DefaultGateway = @{ NoDefault = $true }
                DiskGB = @{ Constant = 60 }
                DnsServer = @{ Constant = '8.8.8.8' }
                Edition = @{ Constant = 'Standard' }
                GuestOS = @{ Constant = 'windows2022srvnext-64' }
                ImageNameDatacenter = @{ Constant = 'Windows Server 2025 Datacenter Evaluation (Desktop Experience)' }
                ImageNameStandard = @{ Constant = 'Windows Server 2025 Standard Evaluation (Desktop Experience)' }
                InputLocale = @{ Constant = 'en-US' }
                LogPath = @{ Expression = '"$(if ($PSScriptRoot) { Join-Path $PSScriptRoot ''logs'' } else { ''.\logs'' })"' }
                NetworkType = @{ Constant = 'nat' }
                Organization = @{ Constant = 'Lab' }
                PostSetupDelayMinutes = @{ Constant = 5 }
                ProductKey = @{ NoDefault = $true }
                RamMB = @{ Constant = 4096 }
                RestartTimeoutMinutes = @{ Constant = 10 }
                ShowConsole = @{ NoDefault = $true }
                ShutdownTimeoutMinutes = @{ Constant = 5 }
                SubnetMask = @{ Constant = '255.255.255.0' }
                SystemLocale = @{ Constant = 'en-US' }
                TempPath = @{ Expression = '"$env:TEMP\VMDeploy"' }
                TimeZone = @{ Constant = 'Pacific Standard Time' }
                TimeoutMinutes = @{ Constant = 90 }
                UserLocale = @{ Constant = 'en-US' }
                VmName = @{ Constant = 'WS2025-Server' }
            }
        }
        '1.0.2' = @{
            Tag = 'v1.0.2'
            HeaderVersion = '1.0.2'
            Settings = @{
                ComputerName = @{ Constant = 'WIN2025' }
                CpuCount = @{ Constant = 2 }
                DefaultGateway = @{ NoDefault = $true }
                DiskGB = @{ Constant = 60 }
                DnsServer = @{ Constant = '8.8.8.8' }
                Edition = @{ Constant = 'Standard' }
                GuestOS = @{ Constant = 'windows2022srvnext-64' }
                ImageNameDatacenter = @{ Constant = 'Windows Server 2025 Datacenter Evaluation (Desktop Experience)' }
                ImageNameStandard = @{ Constant = 'Windows Server 2025 Standard Evaluation (Desktop Experience)' }
                InputLocale = @{ Constant = 'en-US' }
                LogPath = @{ Expression = '"$(if ($PSScriptRoot) { Join-Path $PSScriptRoot ''logs'' } else { ''.\logs'' })"' }
                NetworkType = @{ Constant = 'nat' }
                Organization = @{ Constant = 'Lab' }
                PostSetupDelayMinutes = @{ Constant = 5 }
                ProductKey = @{ NoDefault = $true }
                RamMB = @{ Constant = 4096 }
                RestartTimeoutMinutes = @{ Constant = 10 }
                ShowConsole = @{ NoDefault = $true }
                ShutdownTimeoutMinutes = @{ Constant = 5 }
                SubnetMask = @{ Constant = '255.255.255.0' }
                SystemLocale = @{ Constant = 'en-US' }
                TempPath = @{ Expression = '"$env:TEMP\VMDeploy"' }
                TimeZone = @{ Constant = 'Pacific Standard Time' }
                TimeoutMinutes = @{ Constant = 90 }
                UserLocale = @{ Constant = 'en-US' }
                VmName = @{ Constant = 'WS2025-Server' }
            }
        }
        '1.1.0' = @{
            Tag = 'v1.1.0'
            HeaderVersion = '1.1.0'
            Settings = @{
                ComputerName = @{ Constant = 'WIN2025' }
                CpuCount = @{ Constant = 2 }
                DefaultGateway = @{ NoDefault = $true }
                DiskGB = @{ Constant = 60 }
                DnsServer = @{ Constant = '8.8.8.8' }
                Edition = @{ Constant = 'Standard' }
                GuestOS = @{ Constant = 'windows2022srvnext-64' }
                ImageNameDatacenter = @{ Constant = 'Windows Server 2025 Datacenter Evaluation (Desktop Experience)' }
                ImageNameStandard = @{ Constant = 'Windows Server 2025 Standard Evaluation (Desktop Experience)' }
                InputLocale = @{ Constant = 'en-US' }
                LogPath = @{ NoDefault = $true }
                NetworkType = @{ Constant = 'nat' }
                Organization = @{ Constant = 'Lab' }
                PostSetupDelayMinutes = @{ Constant = 5 }
                ProductKey = @{ NoDefault = $true }
                RamMB = @{ Constant = 4096 }
                RestartTimeoutMinutes = @{ Constant = 10 }
                ShowConsole = @{ NoDefault = $true }
                ShutdownTimeoutMinutes = @{ Constant = 5 }
                SubnetMask = @{ Constant = '255.255.255.0' }
                SystemLocale = @{ Constant = 'en-US' }
                TempPath = @{ NoDefault = $true }
                TimeZone = @{ Constant = 'Pacific Standard Time' }
                TimeoutMinutes = @{ Constant = 90 }
                UserLocale = @{ Constant = 'en-US' }
                VmName = @{ Constant = 'WS2025-Server' }
            }
        }
        '1.2.0' = @{
            Tag = 'v1.2.0'
            HeaderVersion = '1.2.0'
            Settings = @{
                ComputerName = @{ Constant = 'WIN2025' }
                CpuCount = @{ Constant = 2 }
                DefaultGateway = @{ NoDefault = $true }
                DiskGB = @{ Constant = 60 }
                DnsServer = @{ Constant = '8.8.8.8' }
                Edition = @{ Constant = 'Standard' }
                GuestOS = @{ Constant = 'windows2022srvnext-64' }
                ImageNameDatacenter = @{ Constant = 'Windows Server 2025 Datacenter Evaluation (Desktop Experience)' }
                ImageNameStandard = @{ Constant = 'Windows Server 2025 Standard Evaluation (Desktop Experience)' }
                InputLocale = @{ Constant = 'en-US' }
                LogPath = @{ NoDefault = $true }
                NetworkType = @{ Constant = 'nat' }
                Organization = @{ Constant = 'Lab' }
                PostSetupDelayMinutes = @{ Constant = 5 }
                ProductKey = @{ NoDefault = $true }
                RamMB = @{ Constant = 4096 }
                RestartTimeoutMinutes = @{ Constant = 10 }
                ShowConsole = @{ NoDefault = $true }
                ShutdownTimeoutMinutes = @{ Constant = 5 }
                SubnetMask = @{ Constant = '255.255.255.0' }
                SystemLocale = @{ Constant = 'en-US' }
                TempPath = @{ NoDefault = $true }
                TimeZone = @{ Constant = 'Pacific Standard Time' }
                TimeoutMinutes = @{ Constant = 90 }
                UserLocale = @{ Constant = 'en-US' }
                VmName = @{ Constant = 'WS2025-Server' }
            }
        }
    }
}
