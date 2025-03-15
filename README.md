# Windows Server 2022: Deployment Guide

This guide covers step-by-step installation, setup, managing and automation of Windows Server 2022 with Active Directory, DNS and security.

## Table of contents
- [Before you start](#before-you-start)
- [Server setup](#server-setup)
- [Configuring AD DS + DNS](#configuring-ad-ds-dns)
- [Troubleshooting](#troubleshooting)
- [Automation User & Group Creation (via PowerShell)](#automation-user-group-creation)
- [Setting Up GPO for Security](#setting-up-gpo-for-security)

## Before you start

- Setup was tested and used on Virtual Machine, but it must work in real environment too.
- In the current setup, it is assumed that DHCP services will handle manageable router, which is quite common in corporative environment, so Windows Server **will not** handle DHCP services.

## Server setup

**Windows Server side**

1. Installation
    1. Go to [Microsoft Windows Server download page](https://info.microsoft.com/ww-landing-windows-server-2022.html)
    2. Fill up the form and download the ISO file of the Windows Server installer
    3. Next step is to install OS from ISO file. You can find tons of installation guides in the internet.

> While installing Windows Server on the machine it will give you a window with OS type selection. There will be 2 types:
> - Standart Evaluation - designed for small companies and testing environment;
> - Datacenter Evaluation - designed for large companies
>> "Desktop Environment" - stands for UI version of OS (others will be terminal-only) 


## Configuring AD DS + DNS
- **AD DS setup**
    > **Note**: This is example for UI-based setup.
    1. In **Server Manager** app (should open on startup by default) find **"Manage"** button in top right corner.
    2. In new window click on **"Next >"** button (located at the bottom bar).
    3. Choose **"Role-based or feature-based installation"** (should be checked by default), then click **"Next >"**.
    4. Next option will be **"Select a server from the server pool"**. Once again, click **"Next >"**.
    5. In "Server Roles" tab from tons of features we need to select **"Active Directory Domain Services"** and **"DNS Server"**.
    6. In "Features" tab you can select what features you need, but we will use the default ones.
    7. Procceed to click **"Next >"** button until you reach **"Confirmation"** tab (if you want, you can read all of the info about AD DS and DNS Server)
    8. Before you confirm everything, check if everything (AD DS, DNS Server, Group Policy Managment, etc.) persists.
    9. If everything is fine, click on **"Install"** button, sit back and wait.
    10. After reboot, you will see a mark above "Flag" icon. Click on it and find **"Promote this server to a domain controller"** button
    11. In new window find "Add a new forest" and select it. Then type the domain name.
    > **Note:**
    > 
    > `<youromainname>.local` will open the domain only locally (LAN)
    > 
    > `<youromainname>.com/org/etc` will open the domain publicly (WAN)
    > 
    > **Prefered option will be public domain**
    12. In DC Options tab choose the right version of the Windows Server 
    > **Note**: For 2022 cap version will be 2016
    13. In DRSM password field you need to type password, so you can log in in case of emergency
    > **Note**: Better to use different password from your Administrator account.
    > 
    > This password can be used **localy only** and should be used only in case of emergency.
    14. You can skip DNS Options for now
    15. Check NetBIOS domain name, better to leave the default one.
    16. Paths should be default ones. Do not change them.
    17. Review Options tab will show the selected options. You can click on "View Script" to copy the options to store and reuse them.
    18. After prerequesities check click on **"Install"** button and wait.
    19. Reboot the machine

- **DNS and Network setup**
    1. Use hotkey combination **"Win+R"** and type `ncpa.cpl`
    2. Double click on "Ethernet" network and find button "Details".
    3. In the list find **"IPv4 Address"** and remember that.
    > **Note**: Address should be something like `192.168.0.123`
    4. Click RMB on "Ethernet" network and find "Properties".
    5. Find **"Internet Protocol Version 4"** property and double click on it.
    6. IP addres should be obtain automatically (default option), but DNS should be manually configured:
    > `Prefered DNS server: <your-machine-ipv4-address>` (e.g. 192.168.0.123)
    > 
    > `Alternate DNS server: <prefered DNS> ` (leave blank, if you want to use ISPs DNS, I will use 8.8.8.8)

## Automation User & Group Creation
Instead of manually adding every user, you can use automation scripts `<script-name>.ps1`. It can be really helpful for large domains. 
> *You can find the scripts [here](./scripts)*

- SSH tunnel creation

  The most important thing of managing domain and server - remote control. The best and fastest way to get control over machine - SSH tunnel.

  1. Check if OpenSSH is installed on the machine - `Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'`
  2. If OpenSSH.Server is missing, then install it via `Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0`
  3. To start the OpenSSH session type in `Start-Service sshd`
  4. Optional: If you want for OpenSSH session to be automatically started on machine startup type `Set-Service -Name sshd -StartupType Automatic`
  5. Finally, you can check if OpenSSH works - `Get-Service sshd`
 
  Connection should be easy too: open the terminal and type `<user-name>@<local-ip-address>` (e.g. `superAdmin@192.168.0.100`).

- Creating new user

The scripts structure is straightforward - opens the `.csv` file with list of users, checking if user exists in AD, then proceeds to create user account based on data, for each user listed in csv.
> **Note**: `.csv` file can be opened and edited either in Notepad or in Microsoft Office Excel

In `.csv` file (opened with Notepad) first line will represent used fields for each flag that is used on user creation (e.g. Name, Password, Email, OU).
All other lines will contain information for **each user**, splitted by commas, without any spacing. OU information can be tricky - it should be assigned in quotes, so script will read it as one string. 

> **FAQ:** *What `OU=x,DC=y,DC=z` stands for?*
>
> **Answer:** OU - Organizational Unit in your AD (used for department separation, with different policies/permissions). DC - splited name of your domain. For exmaple, if your full domain is `mycooldomain.local`, then DC will be `DC=mycooldomain,DC=local`.

## **Troubleshooting**
> Problem: DNS Server warning about failed synchronization

1. Open ```cmd.exe``` as Administrator.
2. Run ```repadmin /syncall /AdeP``` - it should force synchronization for Active Directory
3. If previous command works fine, then everything is running. Otherwise, run ```repadmin /replsummary``` - checks status accross the domain for errors and/or successes.Procceed by next steps.
4. Run ```repadmin /showrepl``` - it will show the replication summarry of the previous command.
5. Finally, run ```repadmin /syncall /AdeP``` once again. Now it should synchronize.

> Problem: OpenSSH does not work

1. Let's check, if firewall is allowing ssh connection - `Get-NetFirewallRule -Name *ssh*`
2. Find **"Enabled"** and **"Action"** tabs. If they are True/Allow, then everything should be fine.
3. If not, use this - `New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22`
4. If problem persists, check if router firewall rules allow connection
5. Additionally, check for typos in your terminal connection, it must be `<user-name>@<local-ip-address>` (e.g. `superAdmin@192.168.0.100`)

