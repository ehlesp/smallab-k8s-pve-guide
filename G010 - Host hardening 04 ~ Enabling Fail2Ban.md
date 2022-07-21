# G010 - Host hardening 04 ~ Enabling Fail2Ban

To harden both the ssh port and the web interface further, `fail2ban` should be installed and configured to protect from brute-force attacks against those interfaces.

## Installing Fail2ban

Login with `mgrsys`, and execute the `apt install` command.

~~~bash
$ sudo apt install -y fail2ban
~~~

## Configuring Fail2ban

The usual method for configuring Fail2ban is by making a `.local` version of the `/etc/fail2ban/jail.conf` file and just editing that version. This way, you have all your particular fail2ban rules in one file, but if you want to separate concerns on different files, you can do it by creating a file per concern under the `/etc/fail2ban/jail.d` folder.

### _Configuring the **ssh** jail_

1. Open a shell with your `sudo` user, `cd` to `/etc/fail2ban/jail.d` and create an empty file called `01_sshd.conf`.

    ~~~bash
    $ cd /etc/fail2ban/jail.d
    $ sudo touch 01_sshd.conf
    ~~~

2. Edit the `01_sshd.conf` file by inserting the configuration lines below.

    ~~~bash
    [sshd]
    enabled = true
    port = 22
    maxretry = 3
    ~~~

    Regarding the lines above.

    - `[sshd]` identifies the service this jail is applied to.

    - `enabled` turns on the jail for the `sshd` service. This line is also present in the `/etc/fail2ban/jail.d/defaults-debian.conf`.

    - `port` should be the same as the one you've configured for your sshd service, in this case is the standard SSH one.

    - `maxretry` is the number of failed authentication attempts allowed before applying a ban to an IP. Remember to make it the same as the `MaxAuthTries` in your `sshd` configuration, so they correlate.

3. Save the changes and restart the fail2ban service.

    ~~~bash
    $ sudo systemctl restart fail2ban.service
    ~~~

To test the configuration, you should provoke a ban.

1. For this test use another computer if you can, so your usual client system doesn't get banned.

2. Then try to connect through ssh, with a non-existing test user, until you use up the attempts allowed in your configuration.

3. With the default configuration, the ban time lasts 600 seconds (10 minutes).

4. After the banning time is over, the banned IP will be unbanned **automatically**.

5. In your server, check the `/var/log/fail2ban.log`. At the end of the file you should find the lines that indicate you what has happened with the banned IP.

    ~~~log
    2021-02-11 13:32:03,310 fail2ban.jail           [28753]: INFO    Jail 'sshd' started
    2021-02-11 13:38:49,734 fail2ban.filter         [28753]: INFO    [sshd] Found 192.168.1.54 - 2021-02-11 13:38:49
    2021-02-11 13:45:14,844 fail2ban.filter         [28753]: INFO    [sshd] Found 192.168.1.54 - 2021-02-11 13:45:14
    2021-02-11 13:45:15,010 fail2ban.actions        [28753]: NOTICE  [sshd] Ban 192.168.1.54
    2021-02-11 13:55:14,197 fail2ban.actions        [28753]: NOTICE  [sshd] Unban 192.168.1.54
    ~~~

    In the example above I only allowed two attempts, which correspond with the two `INFO` lines right below the `Jail 'sshd' started` one. After them you can see the warning of the same attempting IP being banned. Finally, ten minutes later, the IP is unbanned.

### _Configuring the Proxmox VE jail_

1. `cd` to `/etc/fail2ban/jail.d` and create an empty file called `02_proxmox.conf`.

    ~~~bash
    $ cd /etc/fail2ban/jail.d
    $ sudo touch 02_proxmox.conf
    ~~~

2. Edit the `02_proxmox.conf` file by inserting the configuration lines below.

    ~~~bash
    [proxmox]
    enabled = true
    port = https,http,8006
    filter = proxmox
    logpath = /var/log/daemon.log
    maxretry = 3
    # 10 minutes
    bantime = 600
    ~~~

    Regarding the lines above.

    - `[proxmox]` identifies the service this jail is applied to.

    - `enabled` turns on the jail for the `proxmox` service.

    - `port` lists all the ports that your Proxmox VE platform is currently using.

    - `filter` indicates which filter to use to look for failed authentication attempts in the PVE platform.

    - `logpath` points to the log file that Fail2ban has to monitor, using the `filter` on it to identify failed attempts.

    - `maxretry` is the number of failed authentication attempts allowed before applying a ban to an IP.

    - `bantime` indicates how long the ban should last for any banned IP. The value is in seconds, and 600 is the default for Fail2ban.

3. `cd` to `/etc/fail2ban/filter.d` and create an empty file called `proxmox.conf`.

    ~~~bash
    $ cd /etc/fail2ban/filter.d
    $ sudo touch proxmox.conf
    ~~~

4. Edit the `proxmox.conf` file by inserting the configuration lines below.

    ~~~bash
    [Definition]
    failregex = pvedaemon\[.*authentication (verification )?failure; rhost=<HOST> user=.* msg=.*
    ignoreregex =
    ~~~

    The `[Definition]` above establishes the filtering patterns (regular expressions), in the `failregex` parameter, to detect in the Proxmox VE log the failed authentication attempts. The parameter `ignoreregex` could be filled with patterns to detect false positives, in the case they could happen.

5. Save the changes and restart the fail2ban service.

    ~~~bash
    $ sudo systemctl restart fail2ban.service
    ~~~

To test the configuration, you should provoke a ban.

1. For this test use another computer if you can, so your usual client system doesn't get banned.

2. Then try to log in the PVE web console, with a non-existing test user, until you use up the attempts allowed in your configuration.

3. When your IP is banned, you'll see that your browser won't be able to connect with the PVE web console at all.

4. After the banning time is over, the banned IP will be unbanned **automatically**.

5. In your server, check the `/var/log/fail2ban.log`. At the end of the file you should find the lines that indicate you what happened with the banned IP.

    ~~~log
    2021-02-11 14:38:37,626 fail2ban.jail           [5970]: INFO    Jail 'proxmox' started
    2021-02-11 14:39:11,201 fail2ban.filter         [5970]: INFO    [proxmox] Found 192.168.1.54 - 2021-02-11 14:39:10
    2021-02-11 14:39:16,011 fail2ban.filter         [5970]: INFO    [proxmox] Found 192.168.1.54 - 2021-02-11 14:39:15
    2021-02-11 14:39:20,418 fail2ban.filter         [5970]: INFO    [proxmox] Found 192.168.1.54 - 2021-02-11 14:39:20
    2021-02-11 14:39:20,909 fail2ban.actions        [5970]: NOTICE  [proxmox] Ban 192.168.1.54
    2021-02-11 14:49:20,079 fail2ban.actions        [5970]: NOTICE  [proxmox] Unban 192.168.1.54
    ~~~

    In the example I allowed three attempts, which correspond with the three `INFO` lines right below the `Jail 'proxmox' started` one. After them you can see the warning of the same attempting IP being banned. Finally, ten minutes later, the IP is unbanned.

## Considerations regarding Fail2ban

First, to know more about how to configure `fail2ban`, check the manual for `jail.conf`.

~~~bash
$ man jail.conf
~~~

### _Fail2ban client_

Fail2ban comes with the `fail2ban-client` program to monitor its status. For instance, after applying the configuration explained in this guide, you would see the following.

~~~bash
$ sudo fail2ban-client status
Status
|- Number of jail:      2
`- Jail list:   proxmox, sshd
~~~

Also, you can check each jail with the `fail2ban-client`.

~~~bash
$ sudo fail2ban-client status sshd
Status for the jail: sshd
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/auth.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
~~~

~~~bash
$ sudo fail2ban-client status proxmox
Status for the jail: proxmox
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/daemon.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
~~~

On the other hand, the `fail2ban-client` can also be used to handle the fail2ban underlying server (the `fail2ban-server` daemon that monitors the system logs).

### _Fail2ban configuration files are read in order_

The fail2ban configuration files are read in a particular order: first the `.conf` files, then the `.local` ones. And the configuration files within the `.d/` folders are read in alphabetical order. So, the reading order for the `jail` files would be:

1. `jail.conf`
2. `jail.d/*.conf` (in alphabetical order)
3. `jail.local`
4. `jail.d/*.local` (in alphabetical order).

### _Fail2ban uses `iptables` to enforce the bans_

Fail2ban monitors the log files of the services you tell it to and, if it detects that an IP is banneable under the criteria of its configuration, it will block any offending IP in the `iptables` firewall of your server.

On the other hand, the fail2ban jails themselves will also temporarily appear in the `iptables` rule list when an IP is banned by a concrete jail.

To see the iptables rule list, use `sudo iptables -L`. This could give an output like the following if there has been a banning on each jail in your system.

~~~bash
$ sudo iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination
f2b-sshd   tcp  --  anywhere             anywhere             multiport dports ssh
f2b-proxmox  tcp  --  anywhere             anywhere             multiport dports https,http,8006

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination

Chain f2b-sshd (1 references)
target     prot opt source               destination
RETURN     all  --  anywhere             anywhere

Chain f2b-proxmox (1 references)
target     prot opt source               destination
RETURN     all  --  anywhere             anywhere
~~~

Notice the `f2b-sshd` and `f2b-proxmox` names, they have the name for the Fail2Ban proxmox jails they're related to.

### _Manual banning or unbanning of IPs_

You can manually unban an IP with the following command.

~~~bash
$ sudo fail2ban-client set <jail> banip/unbanip <ip address>
~~~

Notice how you have to specify on which `<jail>` you want to place a ban or lift it. An example of unbanning an IP from the `sshd` jail would be like below.

~~~bash
$ sudo fail2ban-client set sshd unbanip 192.168.1.54
~~~

### _Checking a jail's filter_

The filter of a jail is just a regular expression that weeds out from a given log the lines that indicates to fail2ban if an IP should be banned.

To check that the regular expression of a jail's filter works, you have to use the `fail2ban-regex` command.

~~~bash
fail2ban-regex /path/to/log.file /path/to/fail2ban/filter/configuration.file
~~~

Notice that you can test any filter against any log file. For instance, if you were to check the `proxmox` filter previously explained in this guide, you would do it like the following.

~~~bash
$ sudo fail2ban-regex /var/log/daemon.log /etc/fail2ban/filter.d/proxmox.conf
~~~

The output of the command above will be something like the following.

~~~bash
Running tests
=============

Use   failregex filter file : proxmox, basedir: /etc/fail2ban
Use         log file : /var/log/daemon.log
Use         encoding : UTF-8


Results
=======

Failregex: 8 total
|-  #) [# of hits] regular expression
|   1) [8] pvedaemon\[.*authentication (verification )?failure; rhost=<HOST> user=.* msg=.*
`-

Ignoreregex: 0 total

Date template hits:
|- [# of hits] date format
|  [3421] {^LN-BEG}(?:DAY )?MON Day %k:Minute:Second(?:\.Microseconds)?(?: ExYear)?
|  [1] (?:DAY )?MON Day %k:Minute:Second(?:\.Microseconds)?(?: ExYear)?
`-

Lines: 3422 lines, 0 ignored, 8 matched, 3414 missed
[processed in 0.49 sec]

Missed line(s): too many to print.  Use --print-all-missed to print all 3414 lines
~~~

Notice how it has detected 8 matches: those matches are authentication failures that I've provoked to test the `fail2ban` configuration.

## Relevant system paths

### _Directories_

- `/etc/fail2ban`
- `/etc/fail2ban/filter.d`
- `/etc/fail2ban/jail.d`

### _Files_

- `/etc/fail2ban/filter.d/proxmox.conf`
- `/etc/fail2ban/jail.d/01_sshd.conf`
- `/etc/fail2ban/jail.d/02_proxmox.conf`

## References

### _Fail2ban_

- [How to install Fail2ban on Debian](https://upcloud.com/community/tutorials/install-fail2ban-debian/)
- [How to Setup Fail2ban on Debian 9](https://www.vultr.com/docs/how-to-setup-fail2ban-on-debian-9-stretch)
- [Proxmox VE wiki. Protecting the web interface with fail2ban](https://pve.proxmox.com/wiki/Fail2ban)
- [fail2ban conf file](https://unix.stackexchange.com/questions/456756/fail2ban-conf-file)
- [Fail2ban on Debian Buster - the right way to configure?](https://serverfault.com/questions/997099/fail2ban-on-debian-buster-the-right-way-to-configure)
