# G013 - Host hardening 07 ~ Mitigating CPU vulnerabilities

CPUs also come with bugs and, in some cases, can become security vulnerabilities. At the time of writing this, the most famous cases of such bugs are the **meltdown** and **spectre** vulnerabilities.

## Checking out your CPU's vulnerabilities

To check out what known vulnerabilities your CPU has, perform these steps.

1. Open a shell as your administrator user, and execute the following.

    ~~~bash
    $ cat /proc/cpuinfo | grep bugs
    ~~~

2. The output will be one line per core on your CPU. So, in an old four single-threaded cores Intel CPU like mine it looks like below.

    ~~~bash
    bugs            : cpu_meltdown spectre_v1 spectre_v2 mds msbds_only
    bugs            : cpu_meltdown spectre_v1 spectre_v2 mds msbds_only
    bugs            : cpu_meltdown spectre_v1 spectre_v2 mds msbds_only
    bugs            : cpu_meltdown spectre_v1 spectre_v2 mds msbds_only
    ~~~

As you may expect, the list of vulnerabilities will change depending on the CPU.

## Applying the correct microcode package

To mitigate these bugs, you can install the proper microcode `apt` package for your CPU: the `intel-microcode` or the `amd-microcode` one. But to do so, first you need to enable the proper `apt` sources so those packages can be downloaded in your system.

1. Log in as `mgrsys`, then `cd` to `/etc/apt/sources.list.d`.

    ~~~bash
    $ cd /etc/apt/sources.list.d
    ~~~

2. Create a new file called `debian-nonfree.list`.

    ~~~bash
    $ sudo touch debian-nonfree.list
    ~~~

3. Edit the `debian-nonfree.list` file, filling it with the lines below.

    ~~~bash
    deb http://deb.debian.org/debian bullseye non-free
    deb-src http://deb.debian.org/debian bullseye non-free

    deb http://deb.debian.org/debian-security/ bullseye-security non-free
    deb-src http://deb.debian.org/debian-security/ bullseye-security non-free

    deb http://deb.debian.org/debian bullseye-updates non-free
    deb-src http://deb.debian.org/debian bullseye-updates non-free
    ~~~

    > **BEWARE!**  
    > This sources list is only for Debian 11 Bullseye!

4. Save the file, update `apt` and then install the package that suits your CPU. In my case, I'll apply the `intel-microcode` package.

    ~~~bash
    $ sudo apt update
    $ sudo apt install -y intel-microcode
    ~~~

5. After the package's installation is done, reboot your system.

    ~~~bash
    $ sudo reboot
    ~~~

> **BEWARE!**  
> The microcode package can affect the **performance** of your CPU. Also, the microcode applied may just mitigate rather than completely fix the vulnerabilities on your CPU.

## Relevant system paths

### _Directories_

- `/etc/apt/sources.list.d`
- `/proc`

### _Files_

- `/etc/apt/sources.list.d/debian-nonfree.list`
- `/proc/cpuinfo`

## References

- [Meltdown and Spectre](https://meltdownattack.com/)
- [Microcode on Debian Wiki](https://wiki.debian.org/Microcode)
- [Debian Wiki. SourcesList](https://wiki.debian.org/SourcesList)
