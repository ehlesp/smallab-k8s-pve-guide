# G004 - Host configuration 02 ~ UPS management with NUT

- [Any server must be always connected to an UPS unit](#any-server-must-be-always-connected-to-an-ups-unit)
- [Connecting your UPS with your PVE node using NUT](#connecting-your-ups-with-your-pve-node-using-nut)
- [Checking the NUT logs](#checking-the-nut-logs)
- [Executing instant commands on your UPS unit](#executing-instant-commands-on-your-ups-unit)
- [Other possibilities with NUT](#other-possibilities-with-nut)
- [Relevant system paths](#relevant-system-paths)
  - [Directories](#directories)
  - [Files](#files)
- [References](#references)
  - [Network UPS Tools (NUT)](#network-ups-tools-nut)
  - [Related NUT contents](#related-nut-contents)
  - [About UPS units](#about-ups-units)
- [Navigation](#navigation)

## Any server must be always connected to an UPS unit

You really need to protect your server from electrical surges, power cuts or outages. A common way to achieve that protection is with a Uninterruptible Power Supply (_UPS_) unit, like the one part of this guide's hardware setup described in [the chapter **G001**](G001%20-%20Hardware%20setup.md#the-reference-hardware-setup).

This chapter explains how to make your Proxmox VE host monitor the UPS unit with a generic package called **NUT (Network UPS Tool)**. However, be aware that your UPS unit's brand may already have its own particular software for UPS management.

> [!IMPORTANT]
> **NUT may not support your concrete UPS unit**\
> Still, it may have compatible drivers for your UPS unit's brand. Check in the [NUT hardware compatibility list](https://networkupstools.org/stable-hcl.html) to verify if your brand or model line has compatible drivers there.

## Connecting your UPS with your PVE node using NUT

This chapter works with the _Eaton 3S700D_ UPS unit listed in the [the chapter **G001**](G001%20-%20Hardware%20setup.md#the-reference-hardware-setup). This model (and similar ones) comes with a **USB 2.0 cable** to connect the UPS unit with any computer.

> [!WARNING]
> **This procedure is for UPS units connected through USB**\
> If your UPS unit does not come with a USB cable, **you cannot proceed with the instructions explained below**.

Assuming your UPS unit has the required USB cable, proceed to configure it in your Proxmox VE server:

1. First, check the following:

    - Your server is plugged in one of your UPS's _battery-protected_ sockets.
    - You have your UPS connected with its USB cable to an USB plug in your server.
    - The UPS unit is _on_. If it were not, you would not be able to switch your server on.

2. With your Proxmox VE server running, get into the `pve` node through a `root` shell and execute the `lsusb` command:

    ~~~sh
    $ lsusb
    Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
    Bus 001 Device 003: ID 05e3:0608 Genesys Logic, Inc. Hub
    Bus 001 Device 004: ID 0bda:0129 Realtek Semiconductor Corp. RTS5129 Card Reader Controller
    Bus 001 Device 005: ID 046d:c52b Logitech, Inc. Unifying Receiver
    Bus 001 Device 006: ID 0463:ffff MGE UPS Systems UPS
    Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
    Bus 002 Device 002: ID 152d:0578 JMicron Technology Corp. / JMicron USA Technology Corp. JMS578 SATA 6Gb/s
    ~~~

    The `lsusb` returns a list of the USB devices currently connected to your physical server. Please notice how the _Eaton 3S700D_ UPS unit is listed in the `Bus 001 Device 006` line with the rather misleading name `MGE UPS Systems UPS`, confirming the correct connection of the unit to the `pve` node.

3. Install the NUT software package:

    ~~~sh
    $ apt install -y nut
    ~~~

4. You need to configure NUT properly to make it manage your UPS unit. There are several files to change, start by editing `/etc/nut/nut.conf`. But before you change it, first make a backup of it:

    ~~~sh
    $ cd /etc/nut
    $ cp nut.conf nut.conf.orig
    ~~~

    Now you can edit the `nut.conf` file. In it, there is only one line you have to modify:

    ~~~properties
    MODE=none
    ~~~

    This `MODE` line must be changed into the following:

    ~~~properties
    MODE=standalone
    ~~~

    By setting the `standalone` mode you're enabling NUT to work in local mode or, in other words, it will "worry" only about your `pve` node.

    > [!NOTE]
    > **The `nut.conf` file has comments explaining configuration details**\
    > Check the comments in the `nut.conf` to have a better idea of which are the modes that NUT supports.

5. You need to tell NUT about the UPS unit connected to your system. To do that, you must edit the file `/etc/nut/ups.conf`, so make a backup of it:

    ~~~sh
    $ cp ups.conf ups.conf.orig
    ~~~

    Then, append the following parameters to the `ups.conf` file, although with values fitting for your UPS unit:

    ~~~properties
    [eaton]
      driver = usbhid-ups
      port = auto
      desc = "Eaton 3S700D"
     ~~~

    The parameters above mean this:

    - `[eaton]`\
      This is the name that will identify your UPS unit in NUT. This can be any string of characters, but **without spaces**. Type something there that truly identifies your UPS in a clear manner.

    - `driver`\
      Here you indicate NUT how to connect to your UPS unit. For UPS units with their data port plugged in a USB, the correct value is `usbhid-ups`.

    - `port`\
      For an USB connection this has to be left to `auto`.

    - `desc`\
      This is just a descriptive string where you can type the full name and model of your UPS unit, or anything else you might prefer.

6. At this point, you can check if NUT can start its driver and detect your UPS unit properly:

    ~~~sh
    $ upsdrvctl start
    Network UPS Tools - UPS driver controller 2.8.1
    Network UPS Tools - Generic HID driver 0.52 (2.8.1)
    USB communication driver (libusb 1.0) 0.46
    Using subdriver: MGE HID 1.46
    ~~~

    The command tells you what components it is using and, in the last line, also indicates you what driver NUT used to connect to your particular UPS. In this guide's scenario, you can see it is using the correct `MGE` subdriver.

    On the other hand, if you get the following warnings:

    ~~~sh
    libusb1: Could not open any HID devices: insufficient permissions on everything
    No matching HID UPS found
    upsnotify: notify about state 4 with libsystemd: was requested, but not running as a service unit now, will not spam more about it
    upsnotify: failed to notify about state 4: no notification tech defined, will not spam more about it
    Driver failed to start (exit status=1)
    ~~~

    Just reboot your Proxmox VE server and try the `upsdrvctl start` command again, it should run fine this time.

    > [!NOTE]
    > **Do not worry if you get a "Duplicate driver" warning**\
    > In the output of the `upsdrvctl start` command you may get a warning like this one:
    >
    > `Duplicate driver instance detected (PID file /run/nut/usbhid-ups-eaton.pid exists)! Terminating other driver!`
    >
    > It seems that NUT already creates automatically a driver for the UPS unit in the moment it is configured in the `ups.conf` file. This is not an issue at this point, and NUT itself takes care of this duplicity.

7. Configure the NUT daemon by editing the file `/etc/nut/upsd.conf`. Again, make a backup first:

    ~~~sh
    $ cp upsd.conf upsd.conf.orig
    ~~~

    Edit the `upsd.conf` file to uncomment only the `LISTEN` line referred to the IPv4 connection. It should end looking as follows:

    ~~~properties
    # LISTEN <IP address or name> [<port>]
    LISTEN 127.0.0.1 3493
    # LISTEN ::1 3493
    ~~~

    The `LISTEN` lines declares on which ports the `upsd` daemon will listen, and provides a basic access control mechanism. Uncomment the IPv6 line when you use this protocol in your network setup.

8. In NUT there are also users, which **are NOT the same ones** as in the `passwd` file of your `pve` node. At this point, you require two user:

    - One for the NUT monitor agent (`upsmon`).
    - Other for acting as a NUT ups administrator(`upsadmin`).

    To add them, you must edit the file `/etc/nut/upsd.users`. First, back it up:

    ~~~sh
    $ cp upsd.users upsd.users.orig
    ~~~

    Then, append to `upsd.users` the following configuration block:

    ~~~properties
    [upsmon]
        password = s3c4R3_p4sSw0rD!
        upsmon primary

    [upsadm]
        password = D1Ff3rEnT_s3c4R3_p4sSw0rD!
        actions = SET
        instcmds = ALL
    ~~~

    The parameters shown above mean the following:

    - `[upsmon]`/`[upsadm]`\
      This is the NUT user's name. It can be any string, **but with no spaces**.

    - `password`\
      The NUT user's password. Bear in mind that this is an **unencrypted configuration file**. Be careful with who can access it.

    - `upsmon primary`\
      Roughly speaking, this line means that the NUT user is from a machine directly connected to the UPS unit, and that NUT should be run with high privileges there.
  
      > [!NOTE]
      > **Learn more about UPS primary and secondary types in the NUT official documentation**\
      > The UPS primary and secondary types are further explained [in the NUT `upsmon` man documentation](https://networkupstools.org/docs/man/upsmon.html), in the **UPS types** section.

    - `actions = SET`\
      Allows the NUT user to set values on the managed UPS unit.

    - `instcmds = ALL`\
      Allows the NUT user to execute all available instant commands supported by the managed UPS unit.

9. Finally, configure the NUT monitoring service that watches over the UPS unit. The configuration file you have to edit is `/etc/nut/upsmon.conf`, so back it up:

    ~~~sh
    $ cp upsmon.conf upsmon.conf.orig
    ~~~

    Then, do the following in the `upsmon.conf` file:

    - Search for and comment out the lines of the `RBWARNTIME` and `SHUTDOWNCMD` parameters:

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
      # This should work just about everywhere ... if it doesn't, well, change it,
      # perhaps to a more complicated custom script.
      #
      # Note that while you experiment with the initial setup and want to test how
      # your configuration reacts to power state changes and ultimately when power
      # is reported to go critical, but do not want your system to actually turn
      # off, consider setting the SHUTDOWNCMD temporarily to do something benign -
      # such as posting a message with 'logger' or 'wall' or 'mailx'. Do be careful
      # to plug the UPS back into the wall in a timely fashion.
      #
      # For Windows setup use something like:
      # SHUTDOWNCMD "C:\\WINDOWS\\system32\\shutdown.exe -s -t 0"
      # If you have command line using space character you have to add double quote to them, like this:
      # SHUTDOWNCMD "\"C:\\Program Files\\some command.bat\" -first_arg -second_arg"
      # Or use the old DOS 8.3 file name, like this:
      # SHUTDOWNCMD "C:\\PROGRA~1\\SOMECO~1.bat -first_arg -second_arg"

      #SHUTDOWNCMD "/sbin/shutdown -h +0"
      ~~~

    - Append the following lines at the end of the `upsmon.conf` file:

      ~~~properties
      # --------------------------------------------------------------------------
      # Customized settings

      MONITOR eaton@localhost 1 upsmon s3c4R3_p4sSw0rD! primary
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

    Here is an explanation for all the added parameters in the configuration snippet:

    - `MONITOR`\
      This is the line where you must specify your UPS unit (`eaton@localhost`), the username (`upsmon`) and your NUT user's password (`s3c4R3_p4sSw0rD!`). The number `1` indicates the number of power supplies feeding your system through the connected UPS.

    - `SHUTDOWNCMD`\
      Declares the command to be used to shut down the host. In the line shown in the snippet, the command is prepared to write a log before it executes the system's shut down.

    - `NOTIFYMSG`\
      Each of these lines are assigning a text message to each NOTIFY event. Within each message, the marker `%s` is replaced by the name of the UPS unit producing the event. `upsmon` passes this message to the program wall to notify the event to the system administrator.

    - `NOTIFYFLAG`\
      Each line declare what is to be done at each `NOTIFY` event. Up to three flags can be specified for each event. In the example, all events will be registered in the host's `/var/log/syslog` log file.

    - `RBWARNTIME`\
      When an UPS unit says it needs to have its battery replaced, `upsmon` will generate a `NOTIFY_REPLBATT` event. This parameter means that this warning will be repeated every this many seconds.

10. Before you can try the configuration, restart the NUT-related services to be sure that they load with the right parameters:

    ~~~sh
    $ systemctl restart nut-client.service nut-server.service
    ~~~

    The service's restart will take a couple of seconds, and should not return any line if everything goes fine.

11. Check if the NUT services are working properly with your UPS unit:

    - `upscmd -l upsunitname`\
      Lists the instant commands supported by the UPS unit named `upsunitname` (replace the placeholder string with the name you gave to your UPS back in point 5). Below you can see its output with this guide's UPS unit:

        ~~~sh
        $ upscmd -l eaton
        Instant commands supported on UPS [eaton]:

        beeper.disable - Disable the UPS beeper
        beeper.enable - Enable the UPS beeper
        beeper.mute - Temporarily mute the UPS beeper
        beeper.off - Obsolete (use beeper.disable or beeper.mute)
        beeper.on - Obsolete (use beeper.enable)
        driver.killpower - Tell the driver daemon to initiate UPS shutdown; should be unlocked with driver.flag.allow_killpower option or variable setting
        driver.reload - Reload running driver configuration from the file system (only works for changes in some options)
        driver.reload-or-error - Reload running driver configuration from the file system (only works for changes in some options); return an error if something changed and could not be applied live (so the caller can restart it with new options)
        driver.reload-or-exit - Reload running driver configuration from the file system (only works for changes in some options); exit the running driver if something changed and could not be applied live (so service management framework can restart it with new options)
        load.off - Turn off the load immediately
        load.off.delay - Turn off the load with a delay (seconds)
        load.on - Turn on the load immediately
        load.on.delay - Turn on the load with a delay (seconds)
        shutdown.return - Turn off the load and return when power is back
        shutdown.stayoff - Turn off the load and remain off
        shutdown.stop - Stop a shutdown in progress
        ~~~

    - `upsc upsunitname`\
      Returns the statistics from the UPS unit specified as `upsunitname` (again, replace this string with your own UPS unit's name). See below the output this commands returns for this guide's reference hardware:

        ~~~sh
        $ upsc eaton
        Init SSL without certificate database
        battery.charge: 100
        battery.charge.low: 20
        battery.runtime: 3840
        battery.type: PbAc
        device.mfr: EATON
        device.model: Eaton 3S 700
        device.serial: Blank
        device.type: ups
        driver.debug: 0
        driver.flag.allow_killpower: 0
        driver.name: usbhid-ups
        driver.parameter.pollfreq: 30
        driver.parameter.pollinterval: 2
        driver.parameter.port: auto
        driver.parameter.synchronous: auto
        driver.state: quiet
        driver.version: 2.8.1
        driver.version.data: MGE HID 1.46
        driver.version.internal: 0.52
        driver.version.usb: libusb-1.0.28 (API: 0x100010a)
        input.transfer.high: 264
        input.transfer.low: 184
        outlet.1.desc: PowerShare Outlet 1
        outlet.1.id: 1
        outlet.1.status: on
        outlet.1.switchable: no
        outlet.desc: Main Outlet
        outlet.id: 0
        outlet.switchable: yes
        output.frequency.nominal: 50
        output.voltage: 230.0
        output.voltage.nominal: 230
        ups.beeper.status: enabled
        ups.delay.shutdown: 20
        ups.delay.start: 30
        ups.firmware: 02.08.0010
        ups.load: 4
        ups.mfr: EATON
        ups.model: Eaton 3S 700
        ups.power.nominal: 700
        ups.productid: ffff
        ups.realpower: 22
        ups.serial: Blank
        ups.status: OL
        ups.timer.shutdown: -1
        ups.timer.start: -1
        ups.type: offline / line interactive
        ups.vendorid: 0463
        ~~~

## Checking the NUT logs

NUT's services write logs in the journal of the Proxmox VE system. Look out for them with the `journalctl` command:

- `nut-server` log entries from the NUT server.
- `nut-monitor` log entries from the NUT monitor.
- `upsd` log entries from the UPS daemon.

Remember to check them out, specially when you have created or modified your NUT configuration. For instance, if NUT cannot connect with your UPS unit, you can see in your PVE system's journal warning logs from the NUT monitor:

~~~sh
Aug 26 10:53:52 pve nut-monitor[6684]: UPS eaton@localhost: Not available.
Aug 26 10:53:57 pve nut-monitor[6684]: Poll UPS [eaton@localhost] failed -  Poll UPS [eaton@localhost] failed - [eaton] does not exist on server localhost
~~~

## Executing instant commands on your UPS unit

To execute the so called **instant commands** on your UPS unit (wich you can list with `upscmd -l upsunitname`), you have to use the command `upscmd` with the **NUT administrator user** [defined in the previous section](#connecting-your-ups-with-your-pve-node-using-nut). A safe way to test this is by disabling and enabling the beeper usually embedded in any UPS:

~~~sh
$ upscmd eaton beeper.disable
Username (root): upsadm
Password:
OK
$ upscmd eaton beeper.enable
Username (root): upsadm
Password:
OK
~~~

You can also execute the whole `upscmd` command in just one line:

~~~sh
$ upscmd -u upsadm -p D1Ff3rEnT_s3c4R3_p4sSw0rD! eaton beeper.disable
~~~

> [!WARNING]
> **Use this one-line format only for task automation with shell scripts**\
> Do not execute the `upscmd` with the password in your normal shell, to avoid exposing your password in your user's shell history (the `.bash_history` text file in bash shells).

Also, remember that:

1. You have to check out first with `upscmd -l upsunitname` which are the instant commands supported by your UPS unit.

2. The NUT software cannot really know if the instant command has been executed on the UPS unit. It only sees what the UPS unit is answering back in response to the command's request.

## Other possibilities with NUT

If you feel curious about what else you can do with NUT, there is a pdf document providing a good number of configuration examples. [Get it in this GitHub page](https://github.com/networkupstools/ConfigExamples/releases/tag/book-3.0-20230319-nut-2.8.0).

## Relevant system paths

### Directories

- `/etc/nut`
- `/var/log`

### Files

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

### [Network UPS Tools (NUT)](https://networkupstools.org/)

- [Hardware compatibility list](https://networkupstools.org/stable-hcl.html)
- [Network UPS Tools User Manual](https://networkupstools.org/docs/user-manual.chunked/index.html)
- [Man for `upsmon`](https://networkupstools.org/docs/man/upsmon.html)

- [GitHub. Network UPS Tools project](https://github.com/networkupstools)
  - [NUT Config Examples book. Version 3.0, with corrections up to 2023-03-19](https://github.com/networkupstools/ConfigExamples/releases/tag/book-3.0-20230319-nut-2.8.0)

### Related NUT contents

- [rogerprice.org. Network UPS Tools (NUT). Configuration Examples](http://rogerprice.org/NUT/)
- [ichasco. Instalar y configurar NUT por SNMP](https://blog.ichasco.com/instalar-y-configurar-nut-por-snmp/) (in Spanish)
- [Random Bits. Monitoring a UPS with nut on Debian or Ubuntu Linux](https://blog.shadypixel.com/monitoring-a-ups-with-nut-on-debian-or-ubuntu-linux/)
- [ServerFault. Can't get upsmon service started to monitor (and respond to) remote UPS](https://serverfault.com/questions/865147/cant-get-upsmon-service-started-to-monitor-and-respond-to-remote-ups)
- [mn3m. Configure UPS monitor using NUT on Debian](https://mn3m.info/posts/configure-ups-monitor-using-nut-on-debian/)
- [DIYblindGuy.com. HOWTO: Configure A UPS on Proxmox 5.x](https://diyblindguy.com/howto-configure-ups-on-proxmox/)
- [Reddit. Homelab. UPS Server on Raspberry Pi](https://www.reddit.com/r/homelab/comments/5ssb5h/ups_server_on_raspberry_pi/)
- [Stuart's Notes. Configuring NUT for the Eaton 3S UPS on Ubuntu Linux](https://srackham.wordpress.com/2013/02/27/configuring-nut-for-the-eaton-3s-ups-on-ubuntu-linux/)

### About UPS units

- [The Linux Documentation Project. UPS HowTo](https://tldp.org/HOWTO/UPS-HOWTO/)

## Navigation

[<< Previous (**G003. Host configuration 01**)](G003%20-%20Host%20configuration%2001%20~%20Apt%20sources%2C%20updates%20and%20extra%20tools.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G005. Host configuration 03**) >>](G005%20-%20Host%20configuration%2003%20~%20LVM%20storage.md)
