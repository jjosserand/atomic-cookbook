require 'mixlib/shellout'

module AtomicHelpers
  def kvm_mac_by_ip(ip_address)
    mac_parts = ['52', '54', '00']
    ip_address.split('.')[1..3].each do |octet|
      mac_parts << "%0.2X" % octet
    end

    mac_parts.join(':').downcase
  end

  def resource_dir(ip_address)
    ::File.join(node['atomic']['work_dir'], ip_address)
  end

  def scp_to_atomic_node(ip_address, identity_file, source_file, dest_file)
    cmd = []
    cmd << '/bin/scp'
    cmd << "-i #{identity_file}"
    cmd << source_file
    cmd << dest_file

    scp = Mixlib::ShellOut.new(cmd)
    scp.run_command
    scp.error!
  end

  def run_cmd_on_atomic_node(ip_address, identity_file, command)
    ssh = Mixlib::ShellOut.new("/bin/ssh -i #{identity_file} #{ip_address} #{command}")
    ssh.run_command
    ssh.error!
  end

  def random_password
    (0...8).map { (65 + rand(26)).chr }.join
  end
end
