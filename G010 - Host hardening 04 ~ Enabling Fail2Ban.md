# G010 - Host hardening 04 ~ Enabling Fail2Ban

- [Harden your setup against intrusions with Fail2Ban](#harden-your-setup-against-intrusions-with-fail2ban)
- [Installing Fail2ban](#installing-fail2ban)
- [Configuring Fail2ban](#configuring-fail2ban)
  - [Configuring the ssh jail](#configuring-the-ssh-jail)
    - [Testing the ssh jail configuration](#testing-the-ssh-jail-configuration)
  - [Configuring the Proxmox VE jail](#configuring-the-proxmox-ve-jail)
    - [Testing the Proxmox jail configuration](#testing-the-proxmox-jail-configuration)
- [Considerations regarding Fail2ban](#considerations-regarding-fail2ban)
  - [Fail2ban client](#fail2ban-client)
  - [Fail2ban configuration files are read in order](#fail2ban-configuration-files-are-read-in-order)
  - [Fail2ban uses `iptables` to enforce the bans](#fail2ban-uses-iptables-to-enforce-the-bans)
  - [Manual banning or unbanning of IPs](#manual-banning-or-unbanning-of-ips)
  - [Checking a jail's filter](#checking-a-jails-filter)
- [Relevant system paths](#relevant-system-paths)
  - [Directories](#directories)
  - [Files](#files)
- [References](#references)
  - [Fail2ban](#fail2ban)
- [Navigation](#navigation)

## Harden your setup against intrusions with Fail2Ban

To harden both the ssh port and the web interface of your Proxmox VE standalone server further, install the intrusion prevention Fail2Ban tool to protect those interfaces from anomalous login attempts trying to brute-force their way into your system.

## Installing Fail2ban

Login with `mgrsys`, and execute the `apt install` command.

~~~sh
$ sudo apt install -y fail2ban
~~~

## Configuring Fail2ban

The usual method for configuring Fail2ban is by making a `.local` version of the `/etc/fail2ban/jail.conf` file and just editing that version. This way, you have all your particular Fail2Ban rules in one file. But, if you want to separate concerns on different files, you can do it by creating a file per concern under the `/etc/fail2ban/jail.d` folder.

### Configuring the ssh jail

1. Open a shell with your `sudo` user (`mgrsys` in this guide), `cd` to `/etc/fail2ban/jail.d` and create an empty file called `01_sshd.conf`.

    ~~~sh
    $ cd /etc/fail2ban/jail.d
    $ sudo touch 01_sshd.conf
    ~~~

2. Edit the `01_sshd.conf` file by inserting the configuration lines below.

    ~~~sh
    [sshd]
    enabled = true
    backend = systemd
    port = 22
    maxretry = 3
    ~~~

    Regarding the lines above.

    - `[sshd]`\
      Identifies the service this jail is applied to.

    - `enabled`\
      Enables the jail for the `sshd` service. This line is also present in the `/etc/fail2ban/jail.d/defaults-debian.conf`.

    - `backend`\
      The Debian Linux where Proxmox VE comes installed is _systemd_-based, which means that many of the traditional logs you could use with Fail2Ban to detect attacks have been replaced by the Journal logging system. Hence, you have to enable the `systemd` backend so Fail2Ban can access the logs it needs to monitor to do its job.

    - `port`\
      Should be the same as the one you've configured for your sshd service. In this guide's PVE setup is the standard SSH one.

    - `maxretry`\
      Is the number of failed authentication attempts allowed before applying a ban to an IP. Remember to make it the same as the `MaxAuthTries` in your `sshd` configuration, so they correlate.

3. Save the changes and restart the fail2ban service.

    ~~~sh
    $ sudo systemctl restart fail2ban.service
    ~~~

#### Testing the ssh jail configuration

To test the jail configuration for the ssh service, you should provoke a ban.

1. **Use another computer for this test if you can**. This is to avoid banning the client system from which you usually connect to your PVE server.

2. Then try to connect through ssh **with a non-existing test user**, until you use up the attempts allowed in your configuration.

3. With the default configuration, **the ban time lasts 3600 seconds (one hour)**.

4. After the banning time is over, the banned IP will be unbanned **automatically**.

5. In your server, check the `/var/log/fail2ban.log`. At the end of the file you should find as the most recent lines the logs indicating what has happened with the banned IP.

    ~~~log
    2025-07-12 20:57:00,848 fail2ban.filter         [23578]: INFO    [sshd] Found 10.3.0.1 - 2025-07-12 20:57:00
    2025-07-12 20:57:04,003 fail2ban.filter         [23578]: INFO    [sshd] Found 10.3.0.1 - 2025-07-12 20:57:03
    2025-07-12 20:57:04,003 fail2ban.filter         [23578]: INFO    [sshd] Found 10.3.0.1 - 2025-07-12 20:57:03
    2025-07-12 20:57:04,501 fail2ban.actions        [23578]: NOTICE  [sshd] Ban 10.3.0.1
    2025-07-12 21:57:04,501 fail2ban.actions        [23578]: NOTICE  [sshd] Unban 10.3.0.1
    ~~~

    The configuration allows three login attempts through ssh, which correspond with the three `INFO` lines shown in the log output above. After them, you can see the first `NOTICE` line of the same attempting IP being banned. The final `NOTICE` log line corresponds to the unbanning of the IP after one hour.

### Configuring the Proxmox VE jail

1. `cd` to `/etc/fail2ban/jail.d` and create an empty file called `02_proxmox.conf`.

    ~~~sh
    $ cd /etc/fail2ban/jail.d
    $ sudo touch 02_proxmox.conf
    ~~~

2. Edit the `02_proxmox.conf` file by inserting the configuration lines below.

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

    Regarding the lines above.

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
      Is the number of failed authentication attempts allowed before applying a ban to an IP.

    - `findtime`\
      Time window Fail2Ban will monitor for repeated failed login attempts. In the configuration used in this guide, it will take into account all the attempts that happened in the last two days.

    - `bantime`\
      Indicates how long the ban should last for any banned IP.

3. `cd` to `/etc/fail2ban/filter.d` and create an empty file called `proxmox.conf`.

    ~~~sh
    $ cd /etc/fail2ban/filter.d
    $ sudo touch proxmox.conf
    ~~~

4. Edit the `proxmox.conf` file by inserting the configuration lines below.

    ~~~sh
    [Definition]
    failregex = pvedaemon\[.*authentication failure; rhost=<HOST> user=.* msg=.*
    ignoreregex =
    journalmatch = _SYSTEMD_UNIT=pvedaemon.service
    ~~~

    The `[Definition]` above establishes the filtering pattern to detect anomalous attempts at login into the Proxmox VE system:

    - `failregex`\
      Here goes the regular expressions that help detect in the Proxmox VE log the anomalous authentication attempts.

    - `ignoreregex`\
      Here can go regular expressions for detecting false positives, in case they are known to happen.

    - `journalmatch`\
      Indicates the systemd service to monitor in the Journal logs. In this case is Proxmos VE's daemon.

5. Save the changes and restart the fail2ban service.

    ~~~sh
    $ sudo systemctl restart fail2ban.service
    ~~~

#### Testing the Proxmox jail configuration

To test the configuration, you should provoke a ban.

1. For this test **use another computer if you can**, to avoid banning your usual client system from where you connect to your Proxmox VE server.

2. Then try to log in the PVE web console, with a non-existing test user, until you use up the attempts allowed in your configuration.

3. When your IP is banned, you'll see that your browser won't be able to connect with the PVE web console at all.

4. After the banning time is over, the banned IP will be unbanned **automatically**.

5. In your server, check the `/var/log/fail2ban.log`. At the end of the file you should find the lines that indicate you what happened with the banned IP.

    ~~~log
    2025-07-12 21:37:47,479 fail2ban.filter         [31409]: INFO    [proxmox] Found 10.3.0.1 - 2025-07-12 21:37:47
    2025-07-12 21:37:52,961 fail2ban.filter         [31409]: INFO    [proxmox] Found 10.3.0.1 - 2025-07-12 21:37:52
    2025-07-12 21:38:12,950 fail2ban.filter         [31409]: INFO    [proxmox] Found 10.3.0.1 - 2025-07-12 21:38:12
    2025-07-12 21:38:13,386 fail2ban.actions        [31409]: NOTICE  [proxmox] Ban 10.3.0.1
    2025-07-12 22:38:13,386 fail2ban.actions        [31409]: NOTICE  [proxmox] Unban 10.3.0.1
    ~~~

    The configuration for accessing Proxmox VE allows three attempts, which correspond with the three `INFO` lines shown in the log snippet above. After them, you can see the first `NOTICE` warning of the same attempting IP being banned. The last `NOTICE` entry informs you of the unbanning of the IP after one hour.

## Considerations regarding Fail2ban

First, to know more about how to configure `fail2ban`, check the manual for `jail.conf`.

~~~sh
$ man jail.conf
~~~

### Fail2ban client

Fail2ban comes with the `fail2ban-client` program to monitor its status. For instance, after applying the configuration explained in this guide, you would see the following.

~~~sh
$ sudo fail2ban-client status
Status
|- Number of jail:      2
`- Jail list:   proxmox, sshd
~~~

Also, you can check each jail with the `fail2ban-client`.

~~~sh
$ sudo fail2ban-client status sshd
Status for the jail: sshd
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     3
|  `- Journal matches:  _SYSTEMD_UNIT=sshd.service + _COMM=sshd
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
   |- Currently banned: 0
   |- Total banned:     1
   `- Banned IP list:
~~~

On the other hand, the `fail2ban-client` can also be used to handle the fail2ban underlying server (the `fail2ban-server` daemon that monitors the system logs).

### Fail2ban configuration files are read in order

The fail2ban configuration files are read in a particular order: first the `.conf` files, then the `.local` ones. And the configuration files within the `.d/` folders are read in alphabetical order. So, the reading order for the `jail` files would be:

1. `jail.conf`
2. `jail.d/*.conf` (in alphabetical order)
3. `jail.local`
4. `jail.d/*.local` (in alphabetical order).

### Fail2ban uses `iptables` to enforce the bans

Fail2ban monitors the log files of the services you tell it to and, if it detects that an IP is banneable under the criteria of its configuration, it will block any offending IP in the `iptables` firewall of your server.

On the other hand, the fail2ban jails themselves will also temporarily appear in the `iptables` rule list when an IP is banned by a concrete jail.

To see the iptables rule list, use `sudo iptables -L`. This could give an output like the following **if there has been at least one banning on each jail in your system**.

~~~sh
$ sudo iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination
f2b-proxmox  tcp  --  anywhere             anywhere             multiport dports https,http,8006
f2b-sshd   tcp  --  anywhere             anywhere             multiport dports ssh

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination

Chain f2b-proxmox (1 references)
target     prot opt source               destination
RETURN     all  --  anywhere             anywhere

Chain f2b-sshd (1 references)
target     prot opt source               destination
RETURN     all  --  anywhere             anywhere
~~~

Notice the `f2b-sshd` and `f2b-proxmox` names, they have the name for the Fail2Ban proxmox jails they are related to.

### Manual banning or unbanning of IPs

You can manually unban an IP with the following command:

~~~sh
$ sudo fail2ban-client set <jail> banip/unbanip <ip address>
~~~

Notice how you have to specify on which `<jail>` you want to place a ban or lift it. An example of unbanning an IP from the `sshd` jail would be like this:

~~~sh
$ sudo fail2ban-client set sshd unbanip 10.3.0.1
~~~

### Checking a jail's filter

The filter of a jail is just a regular expression that weeds out from a given log the lines that indicates to Fail2Ban if an IP should be banned.

To check that the regular expression of a jail's filter works, you have to use the `fail2ban-regex` command.

~~~sh
fail2ban-regex [/path/to/log.file | systemd-journal] /path/to/fail2ban/filter/configuration.file
~~~

Notice that you can test any filter against any log file, or the systemd journal. For instance, if you were to check the `proxmox` filter previously explained in this guide, you would do it like the following.

~~~sh
$ sudo fail2ban-regex systemd-journal /etc/fail2ban/filter.d/proxmox.conf
~~~

The output of the command above will be something like the following.

~~~sh
Running tests
=============

Use   failregex filter file : proxmox, basedir: /etc/fail2ban
Use         systemd journal
Use         encoding : UTF-8
Use    journal match : _SYSTEMD_UNIT=pvedaemon.service


Results
=======

Failregex: 5 total
|-  #) [# of hits] regular expression
|   1) [5] pvedaemon\[.*authentication failure; rhost=<HOST> user=.* msg=.*
`-

Ignoreregex: 0 total

Lines: 429 lines, 0 ignored, 5 matched, 424 missed
[processed in 0.04 sec]

Missed line(s): too many to print.  Use --print-all-missed to print all 424 lines
~~~

Notice how the `fail2ban-regex` command reports a total of five matches in the `Failregex` line.

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

### [Fail2ban](https://github.com/fail2ban/fail2ban)

- [How Fail2Ban Works to Protect Services on a Linux Server](https://www.digitalocean.com/community/tutorials/how-fail2ban-works-to-protect-services-on-a-linux-server)
- [How to configure fail2ban with systemd journal?](https://unix.stackexchange.com/questions/268357/how-to-configure-fail2ban-with-systemd-journal)
- [Proxmox VE wiki. Protecting the web interface with fail2ban](https://pve.proxmox.com/wiki/Fail2ban)
- [fail2ban conf file](https://unix.stackexchange.com/questions/456756/fail2ban-conf-file)
- [Fail2ban on Debian Buster - the right way to configure?](https://serverfault.com/questions/997099/fail2ban-on-debian-buster-the-right-way-to-configure)
- [How to install Fail2ban on Debian](https://upcloud.com/community/tutorials/install-fail2ban-debian/)
- [How to Setup Fail2ban on Debian 9](https://www.vultr.com/docs/how-to-setup-fail2ban-on-debian-9-stretch)

## Navigation

[<< Previous (**G009. Host hardening 03**)](G009%20-%20Host%20hardening%2003%20~%20SSH%20key%20pairs%20and%20sshd%20service%20configuration.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G011. Host hardening 05**) >>](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md)
