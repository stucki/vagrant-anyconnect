# Connecting to Cisco Anyconnect through a Vagrant box

## Installation

1. Add the install script for Cisco Anyconnect to the roles/anyconnect/files/ folder.

   The file name needs to match with "anyconnect-linux64-*.sh".

1. Edit `group_vars/all.yml` and change the name of your VPN server

1. Start the Vagrant machine:

    ```
    vagrant up anyconnect-vpn
    ```

1. Connect to this box and install the VPN client

    ```
    vagrant ssh anyconnect-vpn

    # Use this script to install the Cisco Anyconnect VPN client
    $ vpn-install
    ```

1. Configure SSH on your host (`$HOME/.ssh/config`)

    ```
    Host anyconnect-vpn
	    HostName 127.0.0.1
	    Port 2240
	    # It may be necessary to fix this path
	    IdentityFile ~/.vagrant.d/insecure_private_key
	    #IdentityFile ~/vagrant-anyconnect/.vagrant/machines/anyconnect-vpn/libvirt/private_key
	    # The next line adds a Socks5 proxy on port 1080
	    DynamicForward 1080
	    User vagrant
	    StrictHostKeyChecking=no
	    PasswordAuthentication=no
	    LogLevel=FATAL
	    UserKnownHostsFile=/dev/null
	    IdentitiesOnly=yes
	    ForwardAgent=yes

    # Connect to any number of internal hosts through the VPN box
    Host *.internal internal-host.domain.tld
      ProxyCommand ssh -W %h:%p anyconnect-vpn
    ```

1. Connect to the VPN

    ```
    vagrant ssh anyconnect-vpn

    # Use this script to connect using the Cisco Anyconnect VPN client
    $ vpn-connect

    # Alternative: Connect with X11 forwarding and run the graphical VPN client
    ssh -X anyconnect-vpn
    $ /opt/cisco/anyconnect/bin/vpnui
    ```

1. Connect from the host to your destination server which is behind the VPN

    ```
    ssh internal-host.domain.tld
    ```

1. Alternative: Use `sshuttle` to tunnel all traffic from your host through the VPN box

   - Exclude the IP of the VPN gateway (1.2.3.4)
   - Exclude local networks (172.17.0.0/16, 172.19.0.0/16)

    ```
    sshuttle \
        --listen 0.0.0.0 \
        --exclude 1.2.3.4 --exclude 172.17.0.0/16 --exclude 172.19.0.0/16 \
        --remote anyconnect-vpn \
        --dns 0/0
    ```

1. Disconnect and shutdown

    ```
    vagrant ssh anyconnect-vpn

    $ vpn-disconnect

    vagrant halt anyconnect-vpn
    ```
