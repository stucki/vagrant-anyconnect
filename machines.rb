$boxes = [
  {
    :name       => 'anyconnect-vpn',
    :provider   => 'libvirt',
    :image      => 'ubuntu/xenial64',
    :playbook   => 'anyconnect.yml',
    :ssh_port   => '2240',
    :environment => {},
  },
]
