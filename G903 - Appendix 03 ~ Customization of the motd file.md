# G903 - Appendix 03 ~ Customization of the motd file

- [What is the motd](#what-is-the-motd)
- [How to modify the motd](#how-to-modify-the-motd)
- [References](#references)
  - [Debian](#debian)
  - [About customizing the motd](#about-customizing-the-motd)
- [Navigation](#navigation)

## What is the motd

Every time you open a new shell terminal, no matter if remotely or locally, you see a bunch of lines over the starting prompt. In Debian, those lines are stored in the `/etc/motd` file and can be modified or completely replaced by any other text.

## How to modify the motd

The motd is just a text file that you can modify with a text editor like Vim or Nano. First make an `.orig` backup of the `motd` file before editing it. Then edit in any way you want:

~~~sh
$ sudo cp /etc/motd /etc/motd.orig
$ sudo vim /etc/motd
~~~

> [!IMPORTANT]
> **Careful with the `PrintMotd` feature of the SSH daemon configuration**\
> In the `sshd` configuration (found in `/etc/ssh/sshd_config`) there is a `PrintMotd` parameter set to `no`. **Do not change it** to `yes` or you will see the `motd` content printed **twice** when you connect to the motd's system.

## References

### [Debian](https://www.debian.org/)

- [Wiki. `motd`](https://wiki.debian.org/motd).

### About customizing the motd

- [Putorius. Create a Custom MOTD or Login Banner in Linux](https://www.putorius.net/custom-motd-login-screen-linux.html)

## Navigation

[<< Previous (**G902. Appendix 02**)](G902%20-%20Appendix%2002%20~%20Vim%20vimrc%20configuration.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G904. Appendix 04**) >>](G904%20-%20Appendix%2004%20~%20Handling%20VM%20or%20VM%20template%20volumes.md)
