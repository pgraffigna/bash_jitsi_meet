ENV['VAGRANT_DEFAULT_PROVIDER'] = 'libvirt'
IMAGEN = "generic/ubuntu2204"

Vagrant.configure("2") do |config|
  config.ssh.insert_key = false
  config.vm.synced_folder ".", "/vagrant", type: "rsync", disabled: true

  config.vm.define :server do |s|
    s.vm.box = IMAGEN
    s.vm.hostname = "jitsi.home.local"
    s.vm.box_check_update = false
	
    s.vm.provider :libvirt do |v|
      v.disk_bus = 'virtio'
      v.graphics_type = 'none'
      v.memory = 2048
      v.cpus = 2
    end
  end
end
