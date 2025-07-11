# G009 - Host hardening 03 ~ SSH key pairs and `sshd` service configuration

- [Harden your SSH connections with key pairs](#harden-your-ssh-connections-with-key-pairs)
- [SSH key pairs](#ssh-key-pairs)
  - [Stronger key pair for the `root` user](#stronger-key-pair-for-the-root-user)
  - [New key pair for non-`root` users](#new-key-pair-for-non-root-users)
  - [Export your key pairs](#export-your-key-pairs)
- [Hardening the `sshd` service](#hardening-the-sshd-service)
  - [Disabling common pam authentication in ssh logins](#disabling-common-pam-authentication-in-ssh-logins)
  - [Adjusting the `sshd` daemon configuration](#adjusting-the-sshd-daemon-configuration)
    - [Disabling IPv6 protocol](#disabling-ipv6-protocol)
    - [Reducing the login grace period](#reducing-the-login-grace-period)
    - [Disabling the `root` user on ssh](#disabling-the-root-user-on-ssh)
    - [Reducing the number of authentication attempts](#reducing-the-number-of-authentication-attempts)
    - [Disabling password-based logins](#disabling-password-based-logins)
    - [Disabling X11 forwarding](#disabling-x11-forwarding)
    - [Setting up user specific authentication methods](#setting-up-user-specific-authentication-methods)
    - [Other possible changes in ssh configuration](#other-possible-changes-in-ssh-configuration)
    - [Consideration about hardening `sshd`](#consideration-about-hardening-sshd)
- [Relevant system paths](#relevant-system-paths)
  - [Directories](#directories)
  - [Files](#files)
- [References](#references)
  - [General SSH configuration](#general-ssh-configuration)
  - [About SSH key pairs](#about-ssh-key-pairs)
  - [User specific authentication methods in SSH](#user-specific-authentication-methods-in-ssh)
  - [Particular sshd parameters](#particular-sshd-parameters)
  - [About the `authorized_keys` file](#about-the-authorized_keys-file)
  - [About disabling the `root` user](#about-disabling-the-root-user)
  - [About SSH key generation and cryptosystems](#about-ssh-key-generation-and-cryptosystems)
- [Navigation](#navigation)

## Harden your SSH connections with key pairs

To harden the ssh remote connections to your standalone PVE node, there are two main steps to take:

- **First step**\
  To set up and use SSH key pairs instead of passwords.

- **Second step**\
  To harden the `sshd` service configuration in a certain manner.

## SSH key pairs

### Stronger key pair for the `root` user

The `root` user in your PVE host already comes with a generated ssh key pair. Open a terminal as `root` and list the contents of the `.ssh` directory.

~~~sh
$ ls -al .ssh/
total 20
drwx------ 2 root root 4096 Apr 21 17:14 .
drwx------ 4 root root 4096 Jul 11 18:53 ..
lrwxrwxrwx 1 root root   29 Apr 21 17:14 authorized_keys -> /etc/pve/priv/authorized_keys
-rw-r----- 1 root root  117 Apr 21 17:14 config
-rw------- 1 root root 3369 Apr 21 17:14 id_rsa
-rw-r--r-- 1 root root  734 Apr 21 17:14 id_rsa.pub
~~~

The `id_rsa` file has the private key, while the `id_rsa.pub` has the public key. Since this is a key pair encrypted with the [RSA cryptosystem](https://en.wikipedia.org/wiki/RSA_cryptosystem), its strength is directly related to number of bits used to create it. You can check out the bits employed in this key pair with `ssh-keygen`.

~~~sh
$ cd .ssh/
$ ssh-keygen -lf id_rsa
4096 SHA256:+c40qYIXrTV+b0KHWenrgHaD4a8AEPeIHFMwZVAUk5U root@pve (RSA)
~~~

As you can see in the output above, the key pair's length is `4096` bits, which is enough (at the time I write this, I mean) for an RSA-encrypted key pair. But if you want a key pair encrypted with the newer [_Ed25519_ signature scheme](https://en.wikipedia.org/wiki/EdDSA#Ed25519), you can use the `ssh-keygen` command as follows:

1. Make a backup of the current `root`'s key pair.

    ~~~sh
    $ cd .ssh/
    $ cp id_rsa id_rsa.orig
    $ cp id_rsa.pub id_rsa.pub.orig
    ~~~

2. Delete the current key pair.

    ~~~sh
    $ rm -f id_rsa id_rsa.pub
    ~~~

3. Generate a new key pair with the `ssh-keygen` command.

    ~~~sh
    $ ssh-keygen -t ed25519 -a 100 -C "root@pve"
    ~~~

    The options specified mean the following.

    - `-t ed25519`\
      Specifies the type of key to create, `ed25519` in this case.

    - `-a 100`\
      Makes the command execute the specified number of key derivations (`100` here) to make your private key harder to break with brute-force techniques.

    - `-C "root@pve"`\
      To set a comment associated with the generated key pair, most commonly used to put a string following the schema `[username]@[hostname]`.

4. The ssh-keygen command will ask you two things.

    - `Enter file in which to save the key (/root/.ssh/id_ed25519):`
    - `Enter passphrase (empty for no passphrase):`

    Leave both questions empty by pressing `enter`. Then, the whole command's output will look like the following.

    ~~~sh
    Generating public/private ed25519 key pair.
    Enter file in which to save the key (/root/.ssh/id_ed25519):
    Enter passphrase (empty for no passphrase):
    Enter same passphrase again:
    Your identification has been saved in /root/.ssh/id_ed25519
    Your public key has been saved in /root/.ssh/id_ed25519.pub
    The key fingerprint is:
    SHA256:F6Vq9wL1wjAMTtaJRcnTxCtElnV5bz51BpbBc9guWVg root@pve
    The key's randomart image is:
    +--[ED25519 256]--+
    |      +B=Oo oo.BE|
    |     +.+O o+. X +|
    |      ..+.+. o O |
    |        .*.o  o B|
    |        S.= .  =o|
    |       . + o   ..|
    |          . .   .|
    |           .     |
    |                 |
    +----[SHA256]-----+
    ~~~

5. The `ssh-keygen` command has generated a new key pair in your `root`'s `.ssh` directory. You can verify this also with `ssh-keygen`.

    ~~~sh
    $ ssh-keygen -lf id_ed25519
    256 SHA256:F6Vq9wL1wjAMTtaJRcnTxCtElnV5bz51BpbBc9guWVg root@pve (ED25519)
    ~~~

    It should return the same key fingerprint you saw right after generating the new key pair. Also, notice how the bits length informed is 256. Do not worry about this detail, since the Ed25519 signature scheme is different from the RSA cryptosystem.

6. The last important bit to do is to authorize the public key part in the `authorized_keys` file, while also removing the original public key from it.

    ~~~sh
    $ > authorized_keys
    $ cat id_ed25519.pub >> authorized_keys
    ~~~

    > [!WARNING]
    > In a Proxmox VE system, the `root`'s `authorized_keys` is a symlink to `/etc/pve/priv/authorized_keys`, which is used by Proxmox VE to allow nodes in a cluster to communicate with each other through ssh. So, in case of a clustered PVE environment, is expected to see the public keys of other nodes' `root` users authorized in this file.

7. As a final consideration, you could also remove (with `rm`) the backup of the original RSA-based ssh key pair since you won't need it anymore.

### New key pair for non-`root` users

At this point, you just have another user apart from the `root` one: your administrative or `sudo` user, created as `mgrsys` in the previous [**G008** guide](G008%20-%20Host%20hardening%2002%20~%20Alternative%20administrator%20user.md). This one doesn't even have a `.ssh` directory, but that will also be taken care of by the `ssh-keygen` command.

1. Open a shell as `mgrsys`, and verify that there's no `.ssh` folder in its `/home/mgrsys` directory.

    ~~~sh
    $ ls -al
    total 36
    drwx------ 3 mgrsys mgrsys 4096 Jul 11 20:26 .
    drwxr-xr-x 3 root   root   4096 Jun 12 17:07 ..
    -rw------- 1 mgrsys mgrsys  466 Jun 12 17:36 .bash_history
    -rw-r--r-- 1 mgrsys mgrsys  220 Jun 12 17:07 .bash_logout
    -rw-r--r-- 1 mgrsys mgrsys 3526 Jun 12 17:07 .bashrc
    drwxr-xr-x 4 mgrsys mgrsys 4096 Aug 20  2021 .config
    -r-------- 1 mgrsys mgrsys  155 Jul 11 20:26 .google_authenticator
    -rw-r--r-- 1 mgrsys mgrsys  807 Jun 12 17:07 .profile
    -rw-r--r-- 1 mgrsys mgrsys    0 Jun 12 17:33 .sudo_as_admin_successful
    -rw-r--r-- 1 mgrsys mgrsys  293 Aug 20  2021 .vimrc
    ~~~

    There shouldn't be one since new Debian Linux users are not created with such `.ssh` folder.

2. Execute the `ssh-keygen` command to generate a ssh key pair and, as with `root`, just press enter on the questions.

    ~~~sh
    $ ssh-keygen -t ed25519 -a 100 -C "mgrsys@pve"
    Generating public/private ed25519 key pair.
    Enter file in which to save the key (/home/mgrsys/.ssh/id_ed25519):
    Created directory '/home/mgrsys/.ssh'.
    Enter passphrase (empty for no passphrase):
    Enter same passphrase again:
    Your identification has been saved in /home/mgrsys/.ssh/id_ed25519
    Your public key has been saved in /home/mgrsys/.ssh/id_ed25519.pub
    The key fingerprint is:
    SHA256:oW/pYlgU4eDMDpjCyCdXeNymuDsX8fBjP4das1G3rvQ mgrsys@pve
    The key's randomart image is:
    +--[ED25519 256]--+
    |    +.o.         |
    |+o =.=.o         |
    |=+.o* +..        |
    |. ++ +.. .       |
    |    o.* S  . .   |
    |   . ..* .. . .  |
    |    .oo *+.. .   |
    |   o..oo.+=.o    |
    |    o. oo.o..E   |
    +----[SHA256]-----+
    ~~~

3. The new ssh key pair has been saved in the `.ssh` folder created inside your user's `$HOME` path.

    ~~~sh
    $ cd .ssh/
    $ ls
    id_ed25519  id_ed25519.pub
    ~~~

4. Create the `authorized_keys` file.

    ~~~sh
    $ touch authorized_keys ; chmod 600 authorized_keys
    ~~~

5. Append the content of `id_ed25519.pub` into `authorized_keys`.

    ~~~sh
    $ cat id_ed25519.pub >> authorized_keys
    ~~~

6. Copy the `config` file from the `root` user, and change it's ownership.

    ~~~sh
    $ sudo cp /root/.ssh/config config
    $ sudo chown mgrsys:mgrsys config
    ~~~

    This `config` file was generated for `root` by the Proxmox VE installer with a predefined set of admitted ciphers for OpenSSH. Copying it to any other user it's just an extra hardening measure.

### Export your key pairs

Don't forget to export those new key pairs so you can use them to connect to your standalone PVE node. Also remember that you'll need to generate the `.ppk` file from each private key to connect from Windows clients. Check out the [**G901** appendix guide](G901%20-%20Appendix%2001%20~%20Connecting%20through%20SSH%20with%20PuTTY.md) to see how to connect through SSH with PuTTY.

## Hardening the `sshd` service

To do this hardening, you'll need to modify two files that you've already changed before when you enabled the TFA authentication.

- `/etc/pam.d/sshd`
- `/etc/ssh/sshd_config`

So, open a terminal as your administrative `sudo` user `mgrsys` and make a backup of your current `sshd` configuration.

~~~sh
$ cd /etc/pam.d
$ sudo cp sshd sshd.bkp
$ cd /etc/ssh
$ sudo cp sshd_config sshd_config.bkp
~~~

### Disabling common pam authentication in ssh logins

To disable the common `pam` authentication when login through ssh, edit the `/etc/pam.d/sshd` file by commenting out the `@include common-auth` line found at at its top.

~~~sh
# Standard Un*x authentication.
#@include common-auth
~~~

### Adjusting the `sshd` daemon configuration

#### Disabling IPv6 protocol

Although the use of IPv6 seems to be growing, you will not really need it in a internal private networks like the one your system is in. Then, you can safely disable the protocol on the `sshd` service.

1. Edit the current `/etc/ssh/sshd_config` file, enabling the `AddressFamily` parameter with the value `inet`. It should end looking like below.

    ~~~sh
    #Port 22
    AddressFamily inet
    ListenAddress 10.3.0.2
    #ListenAddress ::
    ~~~

    Notice that I've also put a concrete IP in the `ListenAddress` parameter, making the ssh daemon (called `sshd`) to listen only on the interface that corresponds to that IP. In this case, the IP corresponds with the physical Ethernet network card that is in use in the host. By default, the `sshd` process listens in all available interfaces in the host, when set with the default `ListenAddress 0.0.0.0` setting.

2. Save the the change and restart the `ssh` service.

    ~~~sh
    $ sudo systemctl restart sshd.service
    ~~~

3. Using the `ss` and `grep` commands, check if there is any socket listening on the port `22` but with an IPv6 address like `[::1]`.

    ~~~sh
    $ sudo ss -atlnup | grep :22
    tcp   LISTEN 0      128         10.3.0.2:22        0.0.0.0:*    users:(("sshd",pid=30959,fd=3))
    ~~~

    With the `ss` command above, you get a list of all the ports open in your system and on which address, among other details. With `grep` you filter out the lines returned by `ss` to get only the ones which, in this case, have the port `22` opened. In the output above you can see that there's only one line, which corresponds to the IPv4 address where `sshd` is listening, `10.3.0.2` in this case.

#### Reducing the login grace period

By default, the sshd daemon gives any user two full minutes to authenticate. With modern ssh clients and ssh key pair authentication there's no need to have so much time to authenticate, so you can reduce it to just 45 seconds.

1. Edit the current `/etc/ssh/sshd_config` file, uncomment the `LoginGraceTime` parameter and set it to `45`.

    ~~~sh
    # Authentication:

    LoginGraceTime 45
    PermitRootLogin yes
    ~~~

2. Save the the change and restart the `ssh` service.

    ~~~sh
    $ sudo systemctl restart sshd.service
    ~~~

> [!WARNING]
> **Do not set this timer with a too low value in your system**\
> Be aware that, when your server receives several concurrent unauthenticated requests, it will need some time to process them. Also, a human user will need some time to get and type their **TOTP codes**.

#### Disabling the `root` user on ssh

It's a common security measure in Linux servers to **disable** (_never deleting_, mind you) the `root` superuser after creating an administrative substitute `sudo`-enabled user (like `mgrsys`). This is fine for regular Linux servers (virtualized ones included) but not exactly peachy for Proxmox VE.

Proxmox VE uses `root` user for certain tasks like clustering functionality, but **it's not something specifically documented by Proxmox**. So, if you decide to disable the `root` superuser, be aware that you may face unexpected problems in your Proxmox VE system.

Still, given that we're working on a standalone node, we can assume that a standalone Proxmox VE node may use `root` just in a local manner, never to remotely connect anywhere. Assuming this, disabling the ssh remote access for `root` is a simple modification to the `sshd` configuration.

1. Edit the current `/etc/ssh/sshd_config` file, look for the parameter `PermitRootLogin` and change its value to `no`.

    ~~~sh
    # Authentication:

    LoginGraceTime 45
    PermitRootLogin no
    #StrictModes yes
    ~~~

2. Save the change and restart the sshd server.

    ~~~sh
    $ sudo systemctl restart sshd.service
    ~~~

3. Try to log in remotely as `root` through an ssh client. You should get an error message or warning indicating that the server has rejected the connection. In PuTTY you'll see something like the following output.

    ~~~sh
    Using username "root".
    Keyboard-interactive authentication prompts from server:
    | Verification code:
    End of keyboard-interactive prompts from server
    Access denied
    Keyboard-interactive authentication prompts from server:
    | Verification code:
    ~~~

    Notice the **Access denied** line between the two `Keyboard-interactive authentication prompts`. No matter that you input the correct TOTP verification code every time, the server will reject your request. On the other hand, if you try to connect authenticating with a ssh key pair, you'll see a different message.

    ~~~sh
    Using username "root".
    Authenticating with public key "root@pve"
    Server refused public-key signature despite accepting key!
    ~~~

Revert this change when you detect a problem related to a Proxmox VE functionality requiring `root` to connect through ssh.

#### Reducing the number of authentication attempts

By default, the sshd daemon gives users up to six attempts to make the authentication correctly. But those are too many tries for your ssh-key and TOTP based setup.

1. Edit the current `/etc/ssh/sshd_config` file, uncomment the `MaxAuthTries` parameter and set it to `3`.

    ~~~sh
    PermitRootLogin no
    #StrictModes yes
    MaxAuthTries 3
    #MaxSessions 10
    ~~~

2. Save the the change and restart the `ssh` service.

    ~~~sh
    $ sudo systemctl restart sshd.service
    ~~~

#### Disabling password-based logins

You've already disabled the password prompts in ssh logins when you changed the `/etc/pam.d/sshd` file before. Still, the sshd daemon has also an option in the `/etc/ssh/sshd_config` file to allow password-based authentication that is convenient to disable.

1. In the `/etc/ssh/sshd_config`, uncomment the `PasswordAuthentication` parameter and set it to `no`.

    ~~~sh
    # To disable tunneled clear text passwords, change to no here!
    PasswordAuthentication no
    #PermitEmptyPasswords no
    ~~~

2. Save the the change and restart the `ssh` service.

    ~~~sh
    $ sudo systemctl restart sshd.service
    ~~~

#### Disabling X11 forwarding

Proxmox VE does not come with a graphic (X11) environment, so you can disable the forwarding of the X11 system through ssh connections.

1. Edit the current `/etc/ssh/sshd_config` file, setting the value of the `X11Forwarding` parameter to `no`.

    ~~~sh
    #GatewayPorts no
    X11Forwarding no
    #X11DisplayOffset 10
    #X11UseLocalhost yes
    ~~~

2. Save the the change and restart the `ssh` service.

    ~~~sh
    $ sudo systemctl restart sshd.service
    ~~~

#### Setting up user specific authentication methods

It is possible to particularize the authentication methods per user, something that will solve us a problem with the `root` superuser. In our standalone node scenario, we have disabled the ssh access to the `root` user but, for more advanced (clustered) scenarios, you may need to enable the `root` remote access through `ssh`. In such scenarios, the TOTP token is problematic since Proxmox VE uses the `root` superuser for launching certain automated tasks (backups, clustering actions, etc), and automations cannot input TOTP codes.

So, it is better to do the following:

- Generate a particular pam group for users authorized to connect through ssh, but not including `root`.

- Add your `mgrsys` user to this group.

- Adjust the `sshd` configuration to enforce just the ssh keys authentication method for the `root` and any other accounts meant for launching automated tasks through ssh connections.

- Enforce both the ssh keys and the keyboard interactive (for TFA) methods to the ssh authorized group.

- Disable any possible authentication method for any other unauthorized group or user.

1. Create a new group called `sshauth`.

    ~~~sh
    $ sudo addgroup sshauth
    ~~~

2. Add the user you want to be able to connect remotely through ssh to this group.

    ~~~sh
    $ sudo adduser mgrsys sshauth
    ~~~

3. Once more, edit the `/etc/ssh/sshd_config` file, replacing the line below...

    ~~~sh
    AuthenticationMethods keyboard-interactive
    ~~~

    ... with the following configuration block.

    ~~~sh
    # In Proxmox VE, root is used for automated tasks.
    # This means that only the ssh keys can be used for
    # the superuser authentication.
    # This rule should apply to any other account meant to
    # launch automated tasks through ssh connections (like backups).
    Match User root
            AuthenticationMethods publickey

    # Only users from the 'ssauth' group can connect remotely through ssh.
    # They are required to provide both a valid ssh key and a TFA code.
    Match Group sshauth
            AuthenticationMethods publickey,keyboard-interactive

    # Users not in the sshauth group are not allowed to connect through ssh.
    # They won't have any authentication method available.
    Match Group *,!sshauth
            AuthenticationMethods none
    ~~~

4. Save the the change and restart the `sshd` service.

    ~~~sh
    $ sudo systemctl restart sshd.service
    ~~~

You cannot log as `root` through ssh, because you've already disabled that possibility but, if that were still possible, you would see how the server does not ask you the TFA verification code anymore. On the other hand, you can try to open a new non-shared ssh connection with `mgrsys` and check out that it is still asking you for the TFA code.

> [!IMPORTANT]
> Managing SSH access with `Match` rules using `pam` groups is a more practical approach when handling many users.

#### Other possible changes in ssh configuration

There are many other possible adjustments that can be done in the `sshd` service configuration, but some of them can conflict with how Proxmox VE runs. So, beware of the following changes.

- **Adjusting the `MaxStartups` value**\
    When some user tries to connect to your server, that establishes a new unauthenticated or _startup_ connection. Those users trying to connect can be automated processes running in your server, so be mindful of making this value just big enough for your needs.

- **Adjusting the `MaxSessions` value**\
    This parameter indicates how many sessions can be opened from a shared ssh connection. It could happen that some procedure requires to open two or more extra sessions branched out from its original ssh connection, so be careful of not making this value too small or unnecessarily big.

- **IP restrictions**\
    You can specify which IPs can connect to your server through ssh, but this management is better left to the firewall embedded in your standalone PVE node.

- **Changing the port number**\
    This is a common hardening-wise change, but not without it's own share of potential problems. Changing the port means that you'll also have to change the configuration of other systems and clients that may communicate with your server through ssh.

    _My rule of thumb_: change it only if you're going to expose it directly to the public internet and you won't (_although you **absolutely** should_) put a firewall, reverse proxy or any other security solution between your ssh port and the wild.

#### Consideration about hardening `sshd`

Overall, be aware of the services or tasks in your server that require ssh connections to work, like it happens with Proxmox VE, and study the viability of any change to the `sshd` configuration in a **case-by-case** basis.

## Relevant system paths

### Directories

- `/etc/pam.d`
- `/etc/pve/priv`
- `/etc/ssh`
- `/root/.ssh`
- `$HOME/.ssh`

### Files

- `/etc/pam.d/sshd`
- `/etc/pam.d/sshd.bkp`
- `/etc/ssh/sshd_config`
- `/etc/ssh/sshd_config.bkp`
- `/etc/pve/priv/authorized_keys`
- `/root/.ssh/authorized_keys`
- `/root/.ssh/config`
- `/root/.ssh/id_rsa`
- `/root/.ssh/id_rsa.pub`
- `$HOME/.ssh/authorized_keys`
- `$HOME/.ssh/config`
- `$HOME/.ssh/id_rsa`
- `$HOME/.ssh/id_rsa.pub`

## References

### General SSH configuration

- [SSH Essentials: Working with SSH Servers, Clients, and Keys](https://www.digitalocean.com/community/tutorials/ssh-essentials-working-with-ssh-servers-clients-and-keys)
- [5 Linux SSH Security Best Practices To Secure Your Systems](https://phoenixnap.com/kb/linux-ssh-security)
- [6 ssh authentication methods to secure connection (sshd_config)](https://www.golinuxcloud.com/openssh-authentication-methods-sshd-config/)
- [How to Enable/Disable SSH access for a particular user or user group in Linux](https://www.2daygeek.com/allow-deny-enable-disable-ssh-access-user-group-in-linux/)
- [Asegurando SSH (haciendo ssh más seguro)](https://www.linuxtotal.com.mx/index.php?cont=info_seyre_004)
- [Proxmox VE Cluster when SSH Port is Non-standard and Root Login is Disabled](http://jaroker.com/technotes/operations/proxmox/proxmox_cluster/proxmox-ve-cluster-when-ssl-port-is-non-standard-root-login-is-disabled/)

### About SSH key pairs

- [`ssh-keygen` - Generate a New SSH Key](https://www.ssh.com/ssh/keygen/)
- [How to Generate & Set Up SSH Keys on Debian 10](https://phoenixnap.com/kb/generate-ssh-key-debian-10)
- [How to know the SSH key's length?](https://stackoverflow.com/questions/56827341/how-to-know-the-ssh-keys-length)

### User specific authentication methods in SSH

- [Creating user specific authentication methods in SSH](https://security.stackexchange.com/questions/18036/creating-user-specific-authentication-methods-in-ssh)
- [How can I setup OpenSSH per-user authentication methods?](https://serverfault.com/questions/150153/how-can-i-setup-openssh-per-user-authentication-methods)

### Particular sshd parameters

- [Ensure SSH `LoginGraceTime` is set to one minute or less](https://secscan.acron.pl/centos7/5/2/14)
- [In `sshd_config` '`MaxAuthTries`' limits the number of auth failures per connection. What is a connection?](https://unix.stackexchange.com/questions/418582/in-sshd-config-maxauthtries-limits-the-number-of-auth-failures-per-connection)
- [Ensure SSH `MaxAuthTries` is set to 4 or less](https://secscan.acron.pl/centos7/5/2/5)
- [Difference between `maxstartups` and `maxsessions` in `sshd_config`](https://stackoverflow.com/questions/31114690/difference-between-maxstartups-and-maxsessions-in-sshd-config)
- [Systems Administrator’s Lab: OpenSSH MaxStartups](https://crunchtools.com/systems-administrators-lab-openssh-maxstartups/)
- [`sshd_config MaxSessions` parameter](https://unix.stackexchange.com/questions/26170/sshd-config-maxsessions-parameter)

### About the `authorized_keys` file

- [Proxmox v6 default ssh key in authorized_keys file](https://forum.proxmox.com/threads/proxmox-v6-default-ssh-key-in-authorized_keys-file.57898/#post-266842)
    > [!NOTE]
    > In a cluster of several nodes, PVE relies on ssh to perform certain tasks, a working communication in-between the nodes is therefore essential. This is why we share `/etc/pve/priv/known_hosts` as well as the keys via the `pmxcfs [0]` between the hosts.
    >
    > The `/etc/ssh/ssh_known_hosts` is setup to symlink to `/etc/pve/priv/known_hosts`.
    >
    > For a standalone node this does not really matter, but is setup anyway. You can check the fingerprint by `running ssh-keyscan -t rsa <hostname>` and compare it if not sure.
- [Adding own keys to authorized_keys](https://forum.proxmox.com/threads/adding-own-keys-to-authorized_keys.41812/)
- [About `/etc/pve/priv/authorized_keys`](https://forum.proxmox.com/threads/etc-pve-priv-authorized_keys.18561/)
- [Another `/etc/pve/priv/authorized_keys` question](https://forum.proxmox.com/threads/etc-pve-priv-authorized_keys-question.7671/)

### About disabling the `root` user

- [Don't disable root ssh login to PVE as I did, you'll get locked out of containers](https://www.reddit.com/r/Proxmox/comments/dkozht/dont_disable_root_ssh_login_to_pve_as_i_did_youll/)
- [Disable root login](https://forum.proxmox.com/threads/disable-root-login.10512/)

### About SSH key generation and cryptosystems

- [What are ssh-keygen best practices?](https://security.stackexchange.com/questions/143442/what-are-ssh-keygen-best-practices)
- [Secure Secure Shell](https://blog.stribik.technology/2015/01/04/secure-secure-shell.html)
- [EdDSA](https://en.wikipedia.org/wiki/EdDSA#Ed25519)
- [IANIX. Things that use Ed25519](https://ianix.com/pub/ed25519-deployment.html)
- [RSA cryptosystem](https://en.wikipedia.org/wiki/RSA_cryptosystem)
- [What is the -sk ending for ssh key types?](https://security.stackexchange.com/questions/240991/what-is-the-sk-ending-for-ssh-key-types)

## Navigation

[<< Previous (**G008. Host hardening 02**)](G008%20-%20Host%20hardening%2002%20~%20Alternative%20administrator%20user.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G010. Host hardening 04**) >>](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md)
