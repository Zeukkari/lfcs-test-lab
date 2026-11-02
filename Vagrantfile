# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# LFCS study lab
# ---------------
# Three VMs covering the three distro families you can pick from on the real
# LFCS exam (Ubuntu, openSUSE, CentOS Stream / RHEL clones). Each node gets:
#   - a blank second disk for partitioning / filesystems / LVM / encryption practice
#   - a static address on a private network for networking / NFS / Samba / firewall practice
#   - the same baseline toolset installed via package manager
#
# Tune resources with env vars if your host is tight on RAM/CPU:
#   LFCS_CPUS=1 LFCS_MEM=1024 vagrant up

require 'fileutils'

CPUS = (ENV['LFCS_CPUS'] || 2).to_i
MEM  = (ENV['LFCS_MEM']  || 1536).to_i
DISK_MB = (ENV['LFCS_DISK_MB'] || 5120).to_i

NODES = [
  {
    name:    'ubuntu',
    box:     'bento/ubuntu-22.04',
    ip:      '192.168.56.11',
    hostname: 'ubuntu-lfcs',
  },
  {
    name:    'opensuse',
    box:     'bento/opensuse-leap-15.6',
    ip:      '192.168.56.12',
    hostname: 'opensuse-lfcs',
  },
  {
    name:    'rocky',
    box:     'bento/rockylinux-9',
    ip:      '192.168.56.13',
    hostname: 'rocky-lfcs',
  },
  {
    name:    'ubuntu2',
    box:     'bento/ubuntu-22.04',
    ip:      '192.168.56.14',
    hostname: 'ubuntu2-lfcs',
  },
  {
    name:    'rocky2',
    box:     'bento/rockylinux-9',
    ip:      '192.168.56.15',
    hostname: 'rocky2-lfcs',
  },
]

# Shared /etc/hosts entries so the nodes can reach each other by name.
HOSTS_ENTRIES = NODES.map { |n| "#{n[:ip]} #{n[:hostname]}" }.join("\n")

Vagrant.configure('2') do |config|
  config.vm.box_check_update = false

  NODES.each do |node|
    config.vm.define node[:name] do |machine|
      machine.vm.box = node[:box]
      machine.vm.hostname = node[:hostname]
      machine.vm.network 'private_network', ip: node[:ip]

      machine.vm.provider 'virtualbox' do |vb|
        vb.name   = "lfcs-#{node[:name]}"
        vb.cpus   = CPUS
        vb.memory = MEM

        disk_dir  = File.join(File.dirname(__FILE__), '.vagrant', 'disks')
        FileUtils.mkdir_p(disk_dir)
        disk_file = File.join(disk_dir, "#{node[:name]}-storage.vdi")

        unless File.exist?(disk_file)
          vb.customize ['createhd', '--filename', disk_file, '--size', DISK_MB]
        end
        vb.customize [
          'storageattach', :id,
          '--storagectl', 'SATA Controller',
          '--port', 1,
          '--device', 0,
          '--type', 'hdd',
          '--medium', disk_file,
        ]
      end

      machine.vm.provision 'shell', path: 'provision/hosts.sh', args: [HOSTS_ENTRIES]
      machine.vm.provision 'shell', path: 'provision/common.sh'
    end
  end
end
