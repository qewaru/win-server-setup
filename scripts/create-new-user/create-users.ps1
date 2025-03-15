Import-Module ActiveDirectory

$users = Import-Csv "C:\path\to\file.csv" # Don't forget to change path to real one!

foreach ($user in $users) {
    $fullname = "$($user.FirstName) $($user.LastName)"
    $username = $user.SamAccountName

    if (Get-ADUser -F{SamAccountName -eq $username}) {
        Write-Warning "A user account with username $username already exists!"
    } else {
        Write-Host "Adding new user: $fullname ..." -ForegroundColor Cyan
        $userProps = @{
            Name = $fullname
            GivenName = $user.FirstName
            Surname = $user.LastName
            SamAccountName = $user.SamAccountName
            Path = $user.OU
            UserPrincipalName = "$($user.SamAccountName)@<domain-name>.<local/org/com/etc>" # Use your real domain name!
            AccountPassword = (ConvertTo-SecureString $user.Password -AsPlainText -Force)
            Enabled = $true
        }
    }
    New-ADUser @userProps
    Write-Host "The user $fullname successfully created!"
}
