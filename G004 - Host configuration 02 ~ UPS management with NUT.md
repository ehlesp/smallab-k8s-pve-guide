# G004 - Host configuration 02 ~ UPS management with NUT

Any server must be always connected to an UPS! You really need to protect your server from electrical surges, power cuts or outages. Here we'll assume that you already have one UPS plugged by USB to your computer.

The program we're going to use is a generic package called **NUT (Network UPS Tool)**, although be aware that your UPS brand may already have their own particular software for UPS management (like in the case of **APC** and its related `apcupsd` tool for Linux systems).

> **BEWARE!**  
> It could be that NUT doesn't support your concrete UPS model, but it may have compatible drivers for your UPS brand. Check on the [NUT hardware compatibility list](https://networkupstools.org/stable-hcl.html) to verify if your brand or model line has compatible drivers there.

## Connecting your UPS with your pve node using NUT

In this guide, I'll work with my _APC Back-UPS_ unit. This model (and similar ones) comes with a **special USB cable** to connect the UPS with any computer. If your UPS doesn't have this cable, **you won't be able to proceed with the instructions explained below**.

Assuming your UPS unit has the required USB cable, here's how to proceed with its configuration in your server.

1. First, check the following.
    - Your server is plugged in one of your UPS's _protected_ sockets.
    - You have your UPS connected with its special cable to an USB plug in your server.
    - The UPS unit is _on_. Obviously, if it weren't, you wouldn't be able to switch your server on.

2. With your Proxmox VE server running, get into the `pve` node through a `root` shell and execute the `lsusb` command.

    ~~~bash
    $ lsusb
    Bus 002 Device 002: ID 0bc2:3330 Seagate RSS LLC Raptor 3.5" USB 3.0
    Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
    Bus 001 Device 003: ID 0bda:0129 Realtek Semiconductor Corp. RTS5129 Card Reader Controller
    Bus 001 Device 005: ID 051d:0002 American Power Conversion Uninterruptible Power Supply
    Bus 001 Device 004: ID 046d:c52b Logitech, Inc. Unifying Receiver
    Bus 001 Device 002: ID 05e3:0610 Genesys Logic, Inc. Hub
    Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
    ~~~

    The `lsusb` gives you a list of the USB devices currently connected to your physical server. Please notice how my _APC Back-UPS_ unit is listed in the `Bus 001 Device 005` line, confirming the correct connection of the unit to the `pve` node.

3. Now you need to install the **NUT** software package.

    ~~~bash
    $ apt install -y nut
    ~~~

    In the `apt` output, notice the following lines pointing at an issue with the NUT service.

    ~~~bash
    Created symlink /etc/systemd/system/multi-user.target.wants/nut-monitor.service → /lib/systemd/system/nut-monitor.service.
    Job for nut-monitor.service failed because the service did not take the steps required by its unit configuration.
    See "systemctl status nut-monitor.service" and "journalctl -xe" for details.
    Setting up nut-server (2.7.4-13) ...
    Created symlink /etc/systemd/system/multi-user.target.wants/nut-server.service → /lib/systemd/system/nut-server.service.
    nut-driver.service is a disabled or a static unit, not starting it.
    ~~~

    Don't worry about this during the `apt` installation, it's happening because you still have to configure NUT.

4. You need to configure NUT properly so it can manage your UPS unit. There are several files to change, let's start editing `/etc/nut/nut.conf`. But before you change it, firt make a backup of it.

    ~~~bash
    $ cd /etc/nut
    $ cp nut.conf nut.conf.orig
    ~~~

    Now you can edit the `nut.conf` file. In it there's only one line you have to modify.

    ~~~properties
    MODE=none
    ~~~

    This `MODE` line must be changed into the following:

    ~~~properties
    MODE=standalone
    ~~~

    By putting `standalone` you're enabling NUT to work in local mode or, in other words, it will "worry" only about your `pve` node. Please check the comments in the `nut.conf` to have a better idea of which are the modes that NUT supports.

5. You need to tell NUT about the UPS unit connected to your system. To do that, you must edit the file `/etc/nut/ups.conf`, so make a backup of it.

    ~~~bash
    $ cp ups.conf ups.conf.orig
    ~~~

    Then, **append** the following parameters, although with values fitting for your UPS unit.

    ~~~properties
    [apc]
        driver = usbhid-ups
        port = auto
        desc = "APC Back-UPS ES 700"
     ~~~

    I'll explain the parameters above:

    - `[apc]`: this is the name that will identify your UPS unit in NUT. This can be any string of characters, but **without spaces**. It's recommended you type something there that truly identifies your UPS in a clear manner.

    - `driver`: here you indicate NUT how to connect to your UPS unit. For UPS units with their data port plugged in a USB, the correct value is `usbhid-ups`.

    - `port`: for an USB connection this has to be left to `auto`.

    - `desc`: this is just a description string in which you can type the full name and model of your UPS unit, or anything else you might prefer.

6. At this point, we can check if NUT can start its driver and detect your UPS unit properly.

    ~~~bash
    $ upsdrvctl start
    Network UPS Tools - UPS driver controller 2.7.4
    Network UPS Tools - Generic HID driver 0.41 (2.7.4)
    USB communication driver 0.33
    Using subdriver: APC HID 0.96
    ~~~

    The command tells you what components it's using and, in the last line, also indicates you what driver NUT used to connect to your particular UPS. In this guide's example, you can see it's using the correct APC subdriver.

7. Next, let's configure the NUT daemon, so edit the file `/etc/nut/upsd.conf`. Again, make a backup first.

    ~~~bash
    $ cp upsd.conf upsd.conf.orig
    ~~~

    Then, uncomment only the `LISTEN` line referred to the IPv4 connection. It should end looking as follows.

    ~~~properties
    # LISTEN <address> [<port>]
    LISTEN 127.0.0.1 3493
    # LISTEN ::1 3493
    ~~~

    The `LISTEN` lines declares on which ports the `upsd` daemon will listen, and provides a basic access control mechanism. Uncomment the IPv6 line when you use this protocol in your network setup.

8. In NUT there are also users, which are **NOT** the same ones as in the `passwd` file of your `pve` node. At this point, you'll require two user: one for the NUT monitor agent (`upsmon`) and other for acting as a NUT ups administrator(`upsadmin`). To add them, you must edit the file `/etc/nut/upsd.users`. First, back it up.

    ~~~bash
    $ cp upsd.users upsd.users.orig
    ~~~

    Then, **append** the following configuration block.

    ~~~properties
    [upsmon]
        password = s3c4R3_p4sSw0rD!
        upsmon master

    [upsadm]
        password = D1Ff3rEnT_s3c4R3_p4sSw0rD!
        actions = SET
        instcmds = ALL
    ~~~

    The parameters in the lines above mean the following.

    - `[upsmon]`/`[upsadm]` : this is the user's name. It can be any string, **but with no spaces**.

    - `password` : the user's password. Please bear in mind that this is an **unencrypted** configuration file, be careful with who can access it.

    - `upsmon master` : roughly speaking, this line says the user is from a machine directly connected to the UPS unit, and that NUT should be run with `master` privileges there.

    - `actions = SET` : allows the user to set values on the managed UPS unit.

    - `instcmds = ALL` : allows the user to execute all available instant commands supported by the managed UPS unit.

9. Finally, you need to configure the NUT monitoring service that watches over the UPS unit. The configuration file you have to edit is `/etc/nut/upsmon.conf`, so back it up.

    ~~~bash
    $ cp upsmon.conf upsmon.conf.orig
    ~~~

    Then, do the following in the `upsmon.conf` file:

    - Search for and comment out the lines of the `RBWARNTIME` and `SHUTDOWNCMD` parameters.

        ~~~properties
        # --------------------------------------------------------------------------
        # RBWARNTIME - replace battery warning time in seconds
        #
        # upsmon will normally warn you about a battery that needs to be replaced
        # every 43200 seconds, which is 12 hours.  It does this by triggering a
        # NOTIFY_REPLBATT which is then handled by the usual notify structure
        # you've defined above.
        #
        # If this number is not to your liking, override it here.

        #RBWARNTIME 43200
        ~~~

        ~~~properties
        # --------------------------------------------------------------------------
        # SHUTDOWNCMD "<command>"
        #
        # upsmon runs this command when the system needs to be brought down.
        #
        # This should work just about everywhere ... if it doesn't, well, change it.

        #SHUTDOWNCMD "/sbin/shutdown -h +0"
        ~~~

    - **Append** the following lines at the end of the file.

        ~~~properties
        # --------------------------------------------------------------------------
        # Customized settings

        MONITOR apc@localhost 1 upsmon s3c4R3_p4sSw0rD! master
        SHUTDOWNCMD "logger -t upsmon.conf \"SHUTDOWNCMD calling /sbin/shutdown to shut down system\" ; /sbin/shutdown -h +0"

        NOTIFYMSG ONLINE "UPS %s: On line power."
        NOTIFYMSG ONBATT "UPS %s: On battery."
        NOTIFYMSG LOWBATT "UPS %s: Battery is low."
        NOTIFYMSG REPLBATT "UPS %s: Battery needs to be replaced."
        NOTIFYMSG FSD "UPS %s: Forced shutdown in progress."
        NOTIFYMSG SHUTDOWN "Auto logout and shutdown proceeding."
        NOTIFYMSG COMMOK "UPS %s: Communications (re-)established."
        NOTIFYMSG COMMBAD "UPS %s: Communications lost."
        NOTIFYMSG NOCOMM "UPS %s: Not available."
        NOTIFYMSG NOPARENT "upsmon parent dead, shutdown impossible."

        NOTIFYFLAG ONLINE SYSLOG
        NOTIFYFLAG ONBATT SYSLOG
        NOTIFYFLAG LOWBATT SYSLOG
        NOTIFYFLAG REPLBATT SYSLOG
        NOTIFYFLAG FSD SYSLOG
        NOTIFYFLAG SHUTDOWN SYSLOG
        NOTIFYFLAG COMMOK SYSLOG
        NOTIFYFLAG COMMBAD SYSLOG
        NOTIFYFLAG NOCOMM SYSLOG
        NOTIFYFLAG NOPARENT SYSLOG

        RBWARNTIME 7200 # 2 hours
        ~~~

    Here's an explanation for the parameters shown above:

    - **`MONITOR`** : this is the line where you must type the name you gave to your UPS unit (`apc` in the example), the username (`upsmon`) and your NUT user's password (`s3c4R3_p4sSw0rD!`). The number `1` indicates the number of power supplies feeding your system through the connected UPS.

    - **`SHUTDOWN`** : declares the command that is to be used to shut down the host. In the line shown above, it's prepared to write a log before it executes the system's shut down.

    - **`NOTIFYMSG`** : each of these lines are assigning a text message to each NOTIFY event. Within each message, the marker `%s` is replaced by the **name of the UPS** which has produced this event. `upsmon` passes this message to program wall to notify the system administrator of the event.

    - **`NOTIFYFLAG`** : each line declare what is to be done at each `NOTIFY` event. Up to three flags can be specified for each event. In the example, all events will be registered in the host's `/var/log/syslog` log file.

    - **`RBWARNTIME`** : when an UPS says it needs to have its battery replaced, `upsmon` will generate a `NOTIFY_REPLBATT` event. This line says that this warning will be repeated every this many **seconds**.

10. Before you can try the configuration, restart the NUT-related services to be sure that they load with the right parameters.

    ~~~bash
    $ systemctl restart nut-client.service nut-server.service
    ~~~

    The service's restart will take a couple of seconds, and shouldn't return any line if everything goes fine.

11. Check if the NUT services are working properly with your UPS unit.

    - `upscmd -l upsname`: this will list you the instant commands supported by the UPS unit named `upsname` (replace this with the name you gave to your UPS in point 5). Below you can see its output with my UPS unit.

        ~~~bash
        $ upscmd -l apc
        Instant commands supported on UPS [apc]:

        beeper.disable - Disable the UPS beeper
        beeper.enable - Enable the UPS beeper
        beeper.mute - Temporarily mute the UPS beeper
        beeper.off - Obsolete (use beeper.disable or beeper.mute)
        beeper.on - Obsolete (use beeper.enable)
        load.off - Turn off the load immediately
        load.off.delay - Turn off the load with a delay (seconds)
        shutdown.reboot - Shut down the load briefly while rebooting the UPS
        shutdown.stop - Stop a shutdown in progress
        test.panel.start - Start testing the UPS panel
        test.panel.stop - Stop a UPS panel test
        ~~~

    - `upsc upsname`: this returns the statistics of the UPS unit specified as `upsname` (again, here you would put your own UPS unit's name). See below the output it returns in my system.

        ~~~bash
        $ upsc apc
        Init SSL without certificate database
        battery.charge: 100
        battery.charge.low: 10
        battery.charge.warning: 50
        battery.date: not set
        battery.mfr.date: 2018/04/22
        battery.runtime: 2205
        battery.runtime.low: 120
        battery.type: PbAc
        battery.voltage: 13.7
        battery.voltage.nominal: 12.0
        device.mfr: APC
        device.model: Back-UPS ES 700G
        device.serial: 5B1816T44974
        device.type: ups
        driver.name: usbhid-ups
        driver.parameter.pollfreq: 30
        driver.parameter.pollinterval: 2
        driver.parameter.port: auto
        driver.parameter.synchronous: no
        driver.version: 2.7.4
        driver.version.data: APC HID 0.96
        driver.version.internal: 0.41
        input.sensitivity: low
        input.transfer.high: 266
        input.transfer.low: 180
        input.voltage: 230.0
        input.voltage.nominal: 230
        ups.beeper.status: disabled
        ups.delay.shutdown: 20
        ups.firmware: 871.O4 .I
        ups.firmware.aux: O4
        ups.load: 1
        ups.mfr: APC
        ups.mfr.date: 2018/04/22
        ups.model: Back-UPS ES 700G
        ups.productid: 0002
        ups.serial: 5B1816T44974
        ups.status: OL
        ups.timer.reboot: 0
        ups.timer.shutdown: -1
        ups.vendorid: 051d
        ~~~

> **BEWARE!**  
> Don't forget to check the `/var/log/syslog` file to detect any problems with the NUT services!

## Executing instant commands on the UPS unit

To execute the so called **instant commands** on your UPS unit, you have to use the command `upscmd` with your **NUT administrator user** defined previously. A safe way to test this is by disabling and enabling the beeper usually embedded in any UPS.

~~~bash
$ upscmd apc beeper.disable
Username (root): upsadm
Password:
OK
$ upscmd apc beeper.enable
Username (root): upsadm
Password:
OK
~~~

You can also execute the whole `upscmd` command in just one line:

~~~bash
$ upscmd -u upsadm -p D1Ff3rEnT_s3c4R3_p4sSw0rD! apc beeper.disable
~~~

> **BEWARE!**  
> Don't execute the `upscmd` like that in your normal shell, to avoid exposing your password in the shell history (in bash is the `.bash_history` text file). Use this one-line format **only for tasks automatizations in shell scripts**.

Also, remember that:

1. You'll have to check out first with `upscmd -l upsunitname` which are the instant commands supported by your UPS unit.

2. The NUT software doesn't known if the instant command has really been executed on the UPS, it only sees what the UPS unit is answering back in response to the command's request.

## Other possibilities with NUT

If you feel curious about what else you can do with NUT, there's a pdf document that provides a good number of configuration examples. [Get it in this GitHub page](https://github.com/networkupstools/ConfigExamples/releases/tag/book-2.0-20210521-nut-2.7.4).

## Relevant system paths

### _Directories_

- `/etc/nut`
- `/var/log`

### _Files_

- `/etc/nut/nut.conf`
- `/etc/nut/nut.conf.orig`
- `/etc/nut/ups.conf`
- `/etc/nut/ups.conf.orig`
- `/etc/nut/upsd.conf`
- `/etc/nut/upsd.conf.orig`
- `/etc/nut/upsd.users`
- `/etc/nut/upsd.users.orig`
- `/etc/nut/upsmon.conf`
- `/etc/nut/upsmon.conf.orig`
- `/var/log/syslog`

## References

### _NUT_

- [NUT (Network UPS Tool)](https://networkupstools.org/)
- [NUT Hardware compatibility list](https://networkupstools.org/stable-hcl.html)
- [NUT User manual (chunked)](https://networkupstools.org/docs/user-manual.chunked/index.html)
- [NUT documentation and scripts](http://rogerprice.org/NUT/)
- [NUT config examples document on GitHub](https://github.com/networkupstools/ConfigExamples/releases/tag/book-2.0-20210521-nut-2.7.4)
- [Monitorización de un SAI con GNU/Debian Linux](http://index-of.co.uk/SISTEMAS-OPERATIVOS/NUT%20Debian%20UPS%20Monitor.pdf) (in spanish)
- [Instalar y configurar NUT por SNMP](https://blog.ichasco.com/instalar-y-configurar-nut-por-snmp/) (in spanish)
- [Monitoring a UPS with nut on Debian or Ubuntu Linux](https://blog.shadypixel.com/monitoring-a-ups-with-nut-on-debian-or-ubuntu-linux/)
- [Can't get upsmon service started to monitor (and respond to) remote UPS](https://serverfault.com/questions/865147/cant-get-upsmon-service-started-to-monitor-and-respond-to-remote-ups)
- [Configure UPS monitor using NUT on Debian](https://mn3m.info/posts/configure-ups-monitor-using-nut-on-debian/)
- [HOWTO: Configure A UPS on Proxmox 5.x](https://diyblindguy.com/howto-configure-ups-on-proxmox/)
- [UPS Server on Raspberry Pi](https://www.reddit.com/r/homelab/comments/5ssb5h/ups_server_on_raspberry_pi/)
- [Configuring NUT for the Eaton 3S UPS on Ubuntu Linux](https://srackham.wordpress.com/2013/02/27/configuring-nut-for-the-eaton-3s-ups-on-ubuntu-linux/)
- [UPS HowTo](https://tldp.org/HOWTO/UPS-HOWTO/)
