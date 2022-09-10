Vagrant.configure("2") do |config|
	config.vm.box = "ubuntu/jammy64"

	# Port forwarding
	config.vm.network 'forwarded_port', guest: 3306, host: 3306


	config.vm.provider "virtualbox" do |vb|
		vb.name = "mysql.local.x-shell.codes"
		vb.cpus = 1
		vb.memory = 4096
	end
end
