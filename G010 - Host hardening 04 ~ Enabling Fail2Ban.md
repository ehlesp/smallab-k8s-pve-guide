# G010 - Host hardening 04 ~ Enabling Fail2Ban

- [Harden your setup against intrusions with Fail2Ban](#harden-your-setup-against-intrusions-with-fail2ban)
- [Installing Fail2Ban](#installing-fail2ban)
- [Configuring Fail2Ban](#configuring-fail2ban)
  - [Configuring the jail for the SSH service](#configuring-the-jail-for-the-ssh-service)
    - [Testing the sshd jail configuration](#testing-the-sshd-jail-configuration)
  - [Configuring the Proxmox VE jail](#configuring-the-proxmox-ve-jail)
    - [Testing the Proxmox VE jail configuration](#testing-the-proxmox-ve-jail-configuration)
- [Considerations regarding Fail2Ban](#considerations-regarding-fail2ban)
  - [Fail2Ban client](#fail2ban-client)
  - [Fail2Ban configuration files are read in order](#fail2ban-configuration-files-are-read-in-order)
  - [Fail2Ban uses `nftables` to enforce the bans](#fail2ban-uses-nftables-to-enforce-the-bans)
  - [Manual banning or unbanning of IPs](#manual-banning-or-unbanning-of-ips)
  - [Checking a jail's filter](#checking-a-jails-filter)
- [Relevant system paths](#relevant-system-paths)
  - [Directories](#directories)
  - [Files](#files)
- [References](#references)
  - [Fail2Ban](#fail2ban)
- [Navigation](#navigation)

## Harden your setup against intrusions with Fail2Ban

To harden both the SSH port and the web interface of your Proxmox VE standalone server further, install the intrusion prevention Fail2Ban tool to protect those interfaces from anomalous login attempts trying to brute-force their way into your system.

## Installing Fail2Ban

Login with `mgrsys`, and execute the `apt install` command:

~~~sh
$ sudo apt install -y fail2ban
~~~

## Configuring Fail2Ban

The usual method for configuring Fail2Ban is by making a `.local` version of the `/etc/fail2ban/jail.conf` file and just editing that version. This way, you have all your particular Fail2Ban rules in one file. But, if you want to separate concerns in different files, you can do it by creating a file per concern under the `/etc/fail2ban/jail.d` folder.

### Configuring the jail for the SSH service

1. Open a shell with your `sudo` user (`mgrsys` in this guide), `cd` to `/etc/fail2ban/jail.d` and create an empty file called `01_sshd.conf`:

    ~~~sh
    $ cd /etc/fail2ban/jail.d
    $ sudo touch 01_sshd.conf
    ~~~

2. Edit the `01_sshd.conf` file by inserting the configuration lines below:

    ~~~sh
    [sshd]
    enabled = true
    backend = systemd
    port = 22
    maxretry = 3
    ~~~

    Regarding the configuration above:

    - `[sshd]`\
      Identifies the service this jail is applied to.

    - `enabled`\
      Enables the jail for the `sshd` service. This line is also present in the `/etc/fail2ban/jail.d/defaults-debian.conf`.

    - `backend`\
      The Debian Linux where Proxmox VE comes installed is _systemd_-based, which means that many of the traditional logs you could use with Fail2Ban to detect attacks have been replaced by the Journal logging system. Hence, you have to enable the `systemd` backend so Fail2Ban can access the logs it needs to monitor to do its job.

    - `port`\
      Should be the same as the one you've configured for your `sshd` service. In this guide's PVE setup is the standard SSH one.

    - `maxretry`\
      Number of failed authentication attempts allowed before applying a ban to an IP. Remember to make it the same as the `MaxAuthTries` in your `sshd` configuration, so they correlate.

3. Save the changes and restart the Fail2Ban service:

    ~~~sh
    $ sudo systemctl restart fail2ban.service
    ~~~

#### Testing the sshd jail configuration

To test the jail configuration for the SSH service, you should provoke a ban:

1. **Use another computer for this test if you can**. This is to avoid banning the client system from which you usually connect to your Proxmox VE server.

2. Try to connect through SSH **with a non-existing test user**, until you use up the attempts allowed in your configuration.

3. With the default configuration, **the ban time lasts 3600 seconds (one hour)**.

4. After the banning time is over, **the banned IP will be unbanned automatically**.

5. In your server, check the `/var/log/fail2ban.log`. At the end of the file you should find as the most recent lines the logs indicating what has happened with the banned IP:

    ~~~log
    2025-08-27 16:43:52,822 fail2ban.filter         [2825]: INFO    [sshd] Found 10.3.0.1 - 2025-08-27 16:43:52
    2025-08-27 16:44:17,117 fail2ban.filter         [2825]: INFO    [sshd] Found 10.3.0.1 - 2025-08-27 16:44:17
    2025-08-27 16:44:17,117 fail2ban.filter         [2825]: INFO    [sshd] Found 10.3.0.1 - 2025-08-27 16:44:17
    2025-08-27 16:44:17,521 fail2ban.actions        [2825]: NOTICE  [sshd] Ban 10.3.0.1
    ...
    2025-08-27 17:44:17,532 fail2ban.actions        [2825]: NOTICE  [sshd] Unban 10.3.0.1
    ~~~

    The configuration allows three login attempts through SSH, which correspond with the three `INFO` lines shown in the log output above. After them, you can see the first `NOTICE` line of the same attempting IP being banned. The final `NOTICE` log line corresponds to the unbanning of the IP after one hour.

### Configuring the Proxmox VE jail

1. `cd` to `/etc/fail2ban/jail.d` and create an empty file called `02_proxmox.conf`:

    ~~~sh
    $ cd /etc/fail2ban/jail.d
    $ sudo touch 02_proxmox.conf
    ~~~

2. Edit the `02_proxmox.conf` file by inserting the configuration lines below:

    ~~~sh
    [proxmox]
    enabled = true
    port = https,http,8006
    filter = proxmox
    backend = systemd
    maxretry = 3
    findtime = 2d
    bantime = 1h
    ~~~

    Regarding the configuration above:

    - `[proxmox]`\
      Identifies the service this jail is applied to.

    - `enabled`\
      Enables the jail for the `proxmox` service.

    - `backend`\
      Indicates Fail2Ban the system where to find the logging information it needs to run, in this case `systemd`.

    - `port`\
      Lists all the ports that your Proxmox VE platform is currently using.

    - `filter`\
      Specifies which filter to use to look for failed authentication attempts in the PVE platform.

    - `maxretry`\
      Number of failed authentication attempts allowed before applying a ban to an IP.

    - `findtime`\
      Time window Fail2Ban will monitor for repeated failed login attempts. In the configuration used in this guide, it will take into account all the attempts that happened in the last two days.

    - `bantime`\
      Indicates how long the ban should last for any banned IP.

3. `cd` to `/etc/fail2ban/filter.d` and create an empty file called `proxmox.conf`:

    ~~~sh
    $ cd /etc/fail2ban/filter.d
    $ sudo touch proxmox.conf
    ~~~

4. Edit the `proxmox.conf` file by inserting the configuration lines below:

    ~~~sh
    [Definition]
    failregex = pvedaemon\[.*authentication failure; rhost=<HOST> user=.* msg=.*
    ignoreregex =
    journalmatch = _SYSTEMD_UNIT=pvedaemon.service
    ~~~

    The `[Definition]` above establishes the filtering pattern to detect anomalous attempts at login into the Proxmox VE system:

    - `failregex`\
      To specify the regular expressions that help detect in the Proxmox VE log the anomalous authentication attempts.

    - `ignoreregex`\
      To set the regular expressions for detecting false positives, in case they are known to happen.

    - `journalmatch`\
      Indicates the `systemd` service to monitor in the Journal logs. In this case is Proxmox VE's daemon.

5. Save the changes and restart the Fail2Ban service:

    ~~~sh
    $ sudo systemctl restart fail2ban.service
    ~~~

#### Testing the Proxmox VE jail configuration

To test the configuration, you should provoke a ban:

1. For this test **use another computer if you can**, to avoid banning your usual client system from where you connect to your Proxmox VE server.

2. Then try to log in the PVE web console, with a non-existing test user, until you use up the attempts allowed in your configuration.

3. When your IP is banned, you will see that your browser is not be able to connect with the PVE web console at all.

4. After the banning time is over, **the banned IP will be unbanned automatically**.

5. In your server, check the `/var/log/fail2ban.log`. At the end of the file you should find the lines that indicate you what happened with the banned IP:

    ~~~log
    2025-08-27 16:58:49,881 fail2ban.filter         [5927]: INFO    [proxmox] Found 10.3.0.1 - 2025-08-27 16:58:49
    2025-08-27 16:58:55,690 fail2ban.filter         [5927]: INFO    [proxmox] Found 10.3.0.1 - 2025-08-27 16:58:55
    2025-08-27 16:59:00,107 fail2ban.filter         [5927]: INFO    [proxmox] Found 10.3.0.1 - 2025-08-27 16:58:59
    2025-08-27 16:59:00,647 fail2ban.actions        [5927]: NOTICE  [proxmox] Ban 10.3.0.1
    ...
    2025-08-27 17:59:00,653 fail2ban.actions        [5927]: NOTICE  [proxmox] Unban 10.3.0.1
    ~~~

    The configuration for accessing Proxmox VE allows three attempts, which correspond with the three `INFO` lines shown in the log snippet above. After them, you can see the first `NOTICE` warning of the same attempting IP being banned. The last `NOTICE` entry informs you of the unbanning of the IP after one hour.

## Considerations regarding Fail2Ban

First, to know more about how to configure `fail2ban`, check the manual for `jail.conf`:

~~~sh
$ man jail.conf
~~~

### Fail2Ban client

Fail2Ban comes with the `fail2ban-client` program to monitor its status. For instance, after applying the configuration explained in this guide, you would see the following:

~~~sh
$ sudo fail2ban-client status
Status
|- Number of jail:      2
`- Jail list:   proxmox, sshd
~~~

Also, you can also check each jail independently with `fail2ban-client`:

~~~sh
$ sudo fail2ban-client status sshd
Status for the jail: sshd
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- Journal matches:  _SYSTEMD_UNIT=ssh.service + _COMM=sshd
`- Actions
   |- Currently banned: 0
   |- Total banned:     1
   `- Banned IP list:
~~~

~~~sh
$ sudo fail2ban-client status proxmox
Status for the jail: proxmox
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     3
|  `- Journal matches:  _SYSTEMD_UNIT=pvedaemon.service
`- Actions
   |- Currently banned: 1
   |- Total banned:     1
   `- Banned IP list:   10.3.0.1
~~~

On the other hand, `fail2ban-client` can also be used to handle the underlying Fail2Ban server. It is the `fail2ban-server` daemon that monitors the system logs.

### Fail2Ban configuration files are read in order

The Fail2Ban configuration files are read in a particular order: first the `.conf` files, then the `.local` ones. And the configuration files within the `.d/` folders are read in alphabetical order. So, the reading order for the `jail` files would be:

1. `jail.conf`
2. `jail.d/*.conf` (in alphabetical order)
3. `jail.local`
4. `jail.d/*.local` (in alphabetical order)

### Fail2Ban uses `nftables` to enforce the bans

Fail2Ban monitors the log files of the services you tell it to and, if it detects banneable IPs under the criteria of its configuration, it will block any offending IP with the `nftables` firewall integrated in your Proxmox VE server. The rules applied through `nftables` can be seen with the `nft` command:

1. First, you must get the name of the table where the Fail2Ban rules are kept:

    ~~~sh
    $ sudo nft list tables
    table inet f2b-table
    ~~~

    Notice that there is only one table active in the `nftables` firewall, the one for Fail2Ban:

    - `table`\
      Just indicates that the object listed in the output is a table of rules.

    - `inet`\
      Indicate to which address family the rules apply. In this case the rules of the table only apply to IPv4 addresses.

    - `f2b-table`\
      The name of the Fail2Ban (`f2b`) table.

2. Once you know the family and name of the Fail2Ban table, you can see the rules in it with the `nft` command:

    ~~~sh
    $ sudo nft list table inet f2b-table
    table inet f2b-table {
            set addr-set-sshd {
                    type ipv4_addr
            }

            set addr-set-proxmox {
                    type ipv4_addr
                    elements = { 10.3.0.1 }
            }

            chain f2b-chain {
                    type filter hook input priority filter - 1; policy accept;
                    tcp dport 22 ip saddr @addr-set-sshd reject with icmp port-unreachable
                    tcp dport { 80, 443, 8006 } ip saddr @addr-set-proxmox reject with icmp port-unreachable
            }
    }
    ~~~

    The output reveals both sets of banned addresses and the chains of rules applied:

    - The `addr-set-sshd` and `addr-set-proxmox` sets each correspond to one of the jails enabled in Fail2Ban. Notice how in the `addr-set-proxmox` there is already one IP included in the set, meaning that nftables has blocked its access to the Proxmox VE server ports.

    - The `f2b-chain` block contains the rules that block access to the sshd and Proxmox VE servers to banned IPs.

### Manual banning or unbanning of IPs

You can manually unban an IP with the following command:

~~~sh
$ sudo fail2ban-client set <jail> banip/unbanip <ip address>
~~~

Notice how you have to specify on which `<jail>` you want to place a ban or lift it. An example of unbanning an IP from the `sshd` jail would be like this:

~~~sh
$ sudo fail2ban-client set sshd unbanip 10.3.0.1
1
~~~

Notice that the `unbanip` command will return a number that indicates how many IPs have been unbanned. In the example, just one has been releases from the `sshd` jail.

### Checking a jail's filter

The filter of a jail is just a regular expression that weeds out from a given log the lines that indicates to Fail2Ban if an IP should be banned.

To check that the regular expression of a jail's filter works, you have to use the `fail2ban-regex` command:

~~~sh
fail2ban-regex [/path/to/log.file | systemd-journal] /path/to/fail2ban/filter/configuration.file
~~~

Notice that you can test any filter against any log file, or the systemd Journal. For instance, if you were to check the `proxmox` filter previously explained in this guide, you would do this:

~~~sh
$ sudo fail2ban-regex systemd-journal /etc/fail2ban/filter.d/proxmox.conf
~~~

The output of the command above should be something like the following:

~~~sh

Running tests
=============

Use      filter file : proxmox, basedir: /etc/fail2ban
Use         systemd journal
Use         encoding : UTF-8
Use    journal match : _SYSTEMD_UNIT=pvedaemon.service


Results
=======

Failregex: 8 total
|-  #) [# of hits] regular expression
|   1) [8] pvedaemon\[.*authentication failure; rhost=<HOST> user=.* msg=.*
`-

Ignoreregex: 0 total

Lines: 356 lines, 0 ignored, 8 matched, 348 missed
[processed in 0.14 sec]

Missed line(s): too many to print.  Use --print-all-missed to print all 348 lines
~~~

Notice how the `fail2ban-regex` command reports a total of eight matches in the `Failregex` line.

## Relevant system paths

### Directories

- `/etc/fail2ban`
- `/etc/fail2ban/filter.d`
- `/etc/fail2ban/jail.d`

### Files

- `/etc/fail2ban/filter.d/proxmox.conf`
- `/etc/fail2ban/jail.d/01_sshd.conf`
- `/etc/fail2ban/jail.d/02_proxmox.conf`

## References

### [Fail2Ban](https://github.com/fail2ban/fail2ban)

- [Proxmox VE Wiki](https://pve.proxmox.com/wiki/Main_Page)
  - [Protecting the web interface with fail2ban](https://pve.proxmox.com/wiki/Fail2ban)

- [DigitalOcean. How Fail2Ban Works to Protect Services on a Linux Server](https://www.digitalocean.com/community/tutorials/how-fail2ban-works-to-protect-services-on-a-linux-server)
- [StackExchange. Unix & Linux. How to configure fail2ban with systemd journal?](https://unix.stackexchange.com/questions/268357/how-to-configure-fail2ban-with-systemd-journal)
- [StackExchange. Unix & Linux. fail2ban conf file](https://unix.stackexchange.com/questions/456756/fail2ban-conf-file)
- [ServerFault. Fail2ban on Debian Buster - the right way to configure?](https://serverfault.com/questions/997099/fail2ban-on-debian-buster-the-right-way-to-configure)
- [UpCloud. How to install Fail2ban on Debian](https://upcloud.com/resources/tutorials/install-fail2ban-debian/)

## Navigation

[<< Previous (**G009. Host hardening 03**)](G009%20-%20Host%20hardening%2003%20~%20SSH%20key%20pairs%20and%20sshd%20service%20configuration.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G011. Host hardening 05**) >>](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md)
