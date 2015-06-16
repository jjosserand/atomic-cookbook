require 'mixlib/shellout'

module AtomicHelpers
  def kvm_mac_by_ip(ip_address)
    mac_parts = ['52', '54', '00']
    ip_address.split('.')[1..3].each do |octet|
      mac_parts << "%0.2X" % octet
    end

    mac_parts.join(':').downcase
  end

  def atomic_work_dir
    node['atomic']['work_dir']
  end

  def atomic_ssh_key
    ::File.join(atomic_work_dir, 'atomic_ssh_key')
  end

  def atomic_ssh_pub_key
    ::File.join(atomic_work_dir, 'atomic_ssh_key.pub')
  end

  def resource_dir(ip_address)
    ::File.join(atomic_work_dir, ip_address)
  end

  def atomic_file_local_path(ip_address, dest_file)
    ::File.join(atomic_work_dir, ip_address, dest_file.gsub('/', '_'))
  end

  def scp_to_atomic_host(ip_address, source_file, dest_file)
    cmd = []
    cmd << '/bin/scp'
    cmd << "-i #{atomic_ssh_key}"
    cmd << source_file
    cmd << "root@#{ip_address}:#{dest_file}"

    Timeout.timeout(10) do
      scp = Mixlib::ShellOut.new(cmd.join(' '))
      scp.run_command
      scp.error!
    end
  end

  def file_exists_on_atomic_host?(ip_address, file)
    cmd_on_atomic_host_success?(ip_address, "stat #{file}")
  end

  def file_diff_on_atomic_host?(ip_address, file)
    if ! file_exists_on_atomic_host?(ip_address, "stat #{file}")
      return true
    end

    source_file_md5 = Digest::MD5.file(atomic_file_local_path(ip_address, file))

    dest_file_cmd = run_cmd_on_atomic_host(ip_address, "md5sum #{file} | awk '{print $1}'")
    dest_file_md5 = dest_file_cmd.stdout.strip

    source_file_md5.to_s != dest_file_md5
  end

  def run_cmd_on_atomic_host(ip_address, command, timeout_duration=nil)
    timeout_duration = timeout_duration.nil? ? 30 : timeout_duration
    Timeout.timeout(timeout_duration) do
      ssh = Mixlib::ShellOut.new("/bin/ssh -i #{atomic_ssh_key} root@#{ip_address} \"#{command}\"")
      ssh.run_command
      ssh
    end
  end

  def run_cmd_on_atomic_host!(ip_address, command, timeout_duration=nil)
    cmd = run_cmd_on_atomic_host(ip_address, command, timeout_duration)
    cmd.error!
  end

  def cmd_on_atomic_host_success?(ip_address, command, timeout_duration=nil)
    cmd = run_cmd_on_atomic_host(ip_address, command, timeout_duration)
    ! cmd.error?
  end

  def random_password
    (0...8).map { (65 + rand(26)).chr }.join
  end
end
