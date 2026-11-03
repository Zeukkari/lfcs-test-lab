# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# LFCS study lab
# ---------------
# Five VMs covering the three distro families you can pick from on the real
# LFCS exam (Ubuntu, openSUSE, CentOS Stream / RHEL clones), with second
# Ubuntu/Rocky nodes for multi-node exercises. Each node gets:
#   - a blank second disk for partitioning / filesystems / LVM / encryption practice
#   - a static address on a private network for networking / NFS / Samba / firewall practice
#   - the same baseline toolset installed via package manager
#
# Tune resources with env vars if your host is tight on RAM/CPU:
#   LFCS_CPUS=1 LFCS_MEM=1024 vagrant up
#
# Inter-node networking uses a VirtualBox NAT Network (not host-only), on
# every host platform. Host-only adapters need a macOS/Linux driver that can
# be blocked by managed/MDM machines (system-extension approval on macOS);
# NAT Network is a fully software-defined switch inside VirtualBox itself,
# needs no host-level driver or approval on any platform, and gives the
# identical VM-to-VM private subnet. Verified end-to-end (ping, raw TCP:22,
# full cross-node provisioning) on an Apple Silicon Mac under a
# Jamf-managed, system-extension-restricted profile; this choice is kept
# universal rather than Apple-Silicon-only to keep the Vagrantfile on one
# code path - see commit history for the switch from host-only.

require 'fileutils'

CPUS = (ENV['LFCS_CPUS'] || 2).to_i
MEM  = (ENV['LFCS_MEM']  || 1536).to_i
DISK_MB = (ENV['LFCS_DISK_MB'] || 5120).to_i

NATNET_NAME = 'lfcs-test-lab-net'
NATNET_CIDR = '192.168.56.0/24'

# arm64 Apple Silicon VirtualBox builds attach bento's arm64 boxes to a
# "VirtIO Controller" (VirtioSCSI); amd64 builds use "SATA Controller"
# (AHCI). Verified directly: VBoxManage showvminfo on a freshly imported
# arm64 bento/rockylinux-9 VM shows storagecontrollername0="VirtIO
# Controller". If a future box build changes this, `VBoxManage showvminfo
# lfcs-<node> | grep -i controller` on the host tells you the real name.
STORAGE_CONTROLLER = RUBY_PLATFORM.include?('arm64') ? 'VirtIO Controller' : 'SATA Controller'

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

# Create the shared NAT Network once, idempotently, before any VM-affecting
# command. Harmless/no-op if it already exists.
if %w[up reload provision].include?(ARGV[0])
  existing = `VBoxManage natnetwork list 2>/dev/null`
  unless existing.include?(NATNET_NAME)
    system('VBoxManage', 'natnetwork', 'add', '--netname', NATNET_NAME, '--network', NATNET_CIDR, '--enable')
    system('VBoxManage', 'natnetwork', 'modify', '--netname', NATNET_NAME, '--dhcp', 'off')
  end
end

Vagrant.configure('2') do |config|
  config.vm.box_check_update = false

  NODES.each do |node|
    config.vm.define node[:name] do |machine|
      machine.vm.box = node[:box]
      machine.vm.hostname = node[:hostname]

      machine.vm.provider 'virtualbox' do |vb|
        vb.name   = "lfcs-#{node[:name]}"
        vb.cpus   = CPUS
        vb.memory = MEM

        vb.customize ['modifyvm', :id, '--nic2', 'natnetwork', '--nat-network2', NATNET_NAME]

        disk_dir  = File.join(File.dirname(__FILE__), '.vagrant', 'disks')
        FileUtils.mkdir_p(disk_dir)
        disk_file = File.join(disk_dir, "#{node[:name]}-storage.vdi")

        unless File.exist?(disk_file)
          vb.customize ['createhd', '--filename', disk_file, '--size', DISK_MB]
        end
        vb.customize [
          'storageattach', :id,
          '--storagectl', STORAGE_CONTROLLER,
          '--port', 1,
          '--device', 0,
          '--type', 'hdd',
          '--medium', disk_file,
        ]
      end

      machine.vm.provision 'shell', path: 'provision/natnet-static.sh', args: [node[:ip]]
      machine.vm.provision 'shell', path: 'provision/hosts.sh', args: [HOSTS_ENTRIES]
      machine.vm.provision 'shell', path: 'provision/common.sh'
    end
  end
end
