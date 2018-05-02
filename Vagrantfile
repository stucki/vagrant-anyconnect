# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
Vagrant.require_version ">= 1.6.0"
VAGRANTFILE_API_VERSION = "2"

$mount_virtualbox = { create: true, type: "virtualbox", owner: "vagrant", group: "vagrant" }
$mount_rsync      = { create: true, type: "rsync", rsync__exclude: ".git/" }
$mount_opts       = $mount_virtualbox

begin
  load 'machines.rb'
rescue LoadError
  print "Error: machines.rb is missing."
  abort
end

# primary: true does not work as expected - see https://github.com/mitchellh/vagrant/issues/2211
needs_box_argument = ['ssh', 'ssh-config', 'up', 'halt', 'destroy', 'provision', 'reload', 'suspend', 'resume'].include?(ARGV.at(0))
has_box_argument = !ARGV[1].nil?

if needs_box_argument && !has_box_argument
  print "Warning: No box has been defined, falling back to default.\n\n"
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  #$proxy_url=""
  #$proxy_noproxy="localhost,127.0.0.1,.example.com"

  if Vagrant.has_plugin?("vagrant-proxyconf") and not $proxy_url.nil? and not $proxy_url.empty?
    config.proxy.http     = $proxy_url
    config.proxy.https    = $proxy_url
    config.proxy.ftp      = $proxy_url
    config.proxy.no_proxy = $proxy_noproxy
  end

  network       = "192.168.191.0/24"
  domain        = ENV['VAGRANT_DOMAIN'] || "ansible.vagrant"

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.auto_detect = true
    config.cache.scope = :box
    #config.cache.synced_folder_opts = {
    #  type: :nfs,
    #  mount_options: ["rw", "vers=3", "tcp", "nolock"]
    #}
  else
    puts 'WARN:  Vagrant-cachier plugin not detected. Continuing unoptimized.'
  end

  $boxes.each do |opts|
    memory = opts[:memory] || 512
    cpus   = opts[:cpus]   || 1

    if has_box_argument || !needs_box_argument || opts[:primary]
      define_this_box = true
    else
      define_this_box = false
    end

    # Only the primary box will be started automatically
    config.vm.define opts[:name] do |node|
      # Vagrant SSH options
      node.ssh.forward_agent = true
      node.ssh.username = opts[:username] unless opts[:username].nil?
      node.ssh.private_key_path = opts[:key] unless opts[:key].nil?
      node.ssh.extra_args = ["-D", "1080"]

      # Disable the new default behavior introduced in Vagrant 1.7, to
      # ensure that all Vagrant machines will use the same SSH key pair.
      # See https://github.com/mitchellh/vagrant/issues/5005
      #node.ssh.insert_key = false

      for key, value in opts[:environment]
          ENV[key.to_s] = value
      end
#      # unless opts[:environment].nil?

      if not opts[:key].nil?
        if File.file?("/home/vagrant/.ssh/" + File.basename(opts[:key]))
          opts[:key] = "/home/vagrant/.ssh/" + File.basename(opts[:key])
        end
        node.ssh.private_key_path = opts[:key] unless opts[:key].nil?
      end

      # Set the hostname for this machine
      node.vm.hostname = "%s.#{domain}" % opts[:name].to_s

      # Create a forwarded port mapping which allows access to a specific port
      # within the machine from a port on the host machine. In the example below,
      # accessing "localhost:8080" will access port 80 on the guest machine.
      #node.vm.network "forwarded_port", guest: 80, host: 8080

      if opts[:ssh_port]
        # Make the forwarded SSH port configurable
        node.vm.network "forwarded_port", guest: 22, host: opts[:ssh_port]
      end

      # Create a private network, which allows host-only access to the machine
      # using a specific IP.
      # If VirtualBox is throwing errors about existing DHCP servers, check this issue:
      # https://github.com/mitchellh/vagrant/issues/3083
      if opts[:ip] && ['virtualbox', 'lxc'].include?(opts[:provider])
        # Use private networking if possible
        node.vm.network "private_network", ip: opts[:ip], lxc__bridge_name: "vlxcbr0"
      elsif ['virtualbox'].include?(opts[:provider])
        # Otherwise, get private IP through DHCP
        node.vm.network "private_network", type: "dhcp", ip: network
      else
        # Otherwise, don't use private networking
      end

      # vagrant-root is not needed
      #node.vm.synced_folder ".", "/home/vagrant/vagrant-box", create: true, mount_options: ["dmode=700,fmode=600"]
      #node.vm.synced_folder "projects", "/home/vagrant/projects", create: true, mount_options: ["dmode=700,fmode=600"]

      # Mount shared folders
      opts[:mounts].each do |mount|
        node.vm.synced_folder mount[:src], mount[:dest], mount[:opts]
      end unless opts[:mounts].nil?

      # Skip checking for an updated Vagrant box
      #node.vm.box_check_update = false

      node.vm.provision "shell", inline: "sudo apt-get -qq update && sudo apt-get -y install python"

      if ['virtualbox', 'vmware', 'lxc', 'libvirt'].include?(opts[:provider])
        node.vm.box = opts[:image]
        node.vm.box_url = opts[:box_url] unless opts[:box_url].nil?
        node.vm.box_check_update = false
      end

      if opts[:provider] == "virtualbox"
        node.vm.provision "shell", inline: "sudo apt-get -qq update && sudo apt-get -y install python"

        # For information on available options for the Virtualbox provider, please visit:
        # http://docs.vagrantup.com/v2/virtualbox/configuration.html
        node.vm.provider "virtualbox" do |vb|
          vb.name = "%s.#{domain}" % opts[:name].to_s

          # Use headless mode
          vb.gui = false

          # Use VBoxManage to customize the VM
          vb.customize ["modifyvm", :id, "--memory", memory]
          vb.customize ["modifyvm", :id, "--cpus",   cpus]
          vb.customize ["modifyvm", :id, "--name", opts[:name]]
        end
      end

      if opts[:provider] == "vmware"
        # For information on available options for the VMware provider, please visit:
        # http://docs.vagrantup.com/v2/vmware/configuration.html
        node.vm.provider "vmware" do |vmware|
          vmware.vmx['memsize']  = memory
          vmware.vmx['numvcpus'] = cpus
          vmware.vmx['displayName'] = "%s.#{domain}" % opts[:name].to_s
        end
      end

      if opts[:provider] == "docker"
        # For information on available options for the Docker provider, please visit:
        # http://docs.vagrantup.com/v2/docker/configuration.html
        node.vm.provider "docker" do |d|
          d.image = opts[:image]
          d.cmd = opts[:cmd] unless opts[:cmd].nil?
          d.has_ssh = true
        end
      end

      if opts[:provider] == "lxc"
        # For information on available options for the Virtualbox provider, please visit:
        # http://docs.vagrantup.com/v2/virtualbox/configuration.html
        node.vm.provider "lxc" do |lxc|
          lxc.container_name = "%s.#{domain}" % opts[:name].to_s
          lxc.customize "cgroup.memory.limit_in_bytes", memory.to_s + "M"
        end
      end

      if opts[:provider] == "libvirt"
        # For information on available options for the Virtualbox provider, please visit:
        # http://docs.vagrantup.com/v2/virtualbox/configuration.html
        node.vm.provider "libvirt" do |libvirt|
          libvirt.driver = "kvm"
          libvirt.memory = memory
          libvirt.cpus = cpus
          libvirt.default_prefix = ''
        end
      end

      if opts[:playbook]
        # For information on available options for Ansible provisioning, please visit:
        # http://docs.vagrantup.com/v2/provisioning/ansible.html
        node.vm.provision "ansible" do |ansible|
          ansible.playbook = opts[:playbook]
          #ansible.verbose = true
          ansible.vault_password_file = opts[:ansible_vault_password_file] if opts[:ansible_vault_password_file]
        end
      end
    end if define_this_box
  end
end
