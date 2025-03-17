Import-Module GroupPolicy

New-GPO -Name "Security Baseline" -Comment "Default must-have configuration" # You can change the name and comment that will fit your domain
New-GPLink -Name "Security Baseline" -Target "OU=Users,DC=domainname,DC=com" # Linking the GPO to the domain and OU (in that case it will be all Users)

# Setting up password policy
# 1. Password length must be 12+ characters
# 2. Password must be complex (uppercase/lowercase characters, numbers & symbols)

Set-GPRegistryValue -Name "Security Baseline" -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
-ValueName "MinimumPasswordLength" -Type DWord -Value 12 # Value = length of password

Set-GPRegistryValue -Name "Security Baseline" -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
-ValueName "PasswordComplexity" -Type DWord -Value 1  # 1 = Enabled, 0 = Disabled


# Disabling CMD and Control Panel for non-admin users
Set-GPRegistryValue -Name "Security Baseline" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
-ValueName "NoControlPanel" -Type DWord -Value 1  # 1 = Disabled, 0 = Enabled

Set-GPRegistryValue -Name "Security Baseline" -Key "HKCU\Software\Policies\Microsoft\Windows\System" `
-ValueName "DisableCMD" -Type DWord -Value 1  # 1 = Disabled, 0 = Enabled


# Optional:
# Restriction of USB storage - prevent using malicious USB drives
# Set-GPRegistryValue -Name "Security Baseline" -Key "HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR" `
# -ValueName "Start" -Type DWord -Value 4


# Force update of GPO
gpupdate /force

# Optional:
# Forcing to apply new GPO rules for all computers in the domain
# Invoke-Command -ComputerName (Get-ADComputer -Filter *).Name -ScriptBlock { gpupdate /force }
