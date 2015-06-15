require 'chef/provider/lwrp_base'

class Chef
  class Provider
    class AtomicHost < Chef::Provider::LWRPBase
      provides :atomic_host

      use_inline_resources

      def whyrun_supported?
        true
      end

      include AtomicHelpers

      action :create do

        ip_address  = new_resource.ip_address
        mac_address = kvm_mac_by_ip(ip_address)
        role        = new_resource.role.to_s
        password    = new_resource.password.nil? ? (0...8).map { (65 + rand(26)).chr }.join : new_resource.password

        base_image     = ::File.join(node['atomic']['work_dir'], node['atomic']['image_version']).sub('qcow2.xz', 'qcow2')
        resource_dir   = ::File.join(node['atomic']['work_dir'], ip_address)
        node_disk_file = ::File.join(resource_dir, 'disk.qcow2')
        init_iso       = ::File.join(resource_dir, 'cloud_init.iso')
        meta_data_file = ::File.join(resource_dir, 'meta-data')
        user_data_file = ::File.join(resource_dir, 'user-data')

        atomic_ssh_key     = ::File.join(node['atomic']['work_dir'], 'atomic_ssh_key')
        atomic_ssh_pub_key = ::File.join(node['atomic']['work_dir'], 'atomic_ssh_key.pub')

        ssh_keys = [ ::File.read(atomic_ssh_pub_key) ]
        unless new_resource.ssh_keys.empty?
          ssh_keys += new_resource.ssh_keys
        end

        directory resource_dir do
          owner 'root'
          group 'root'
          mode '0755'
          action :create
        end

        remote_file "#{new_resource.node_name} disk file" do
          path node_disk_file
          source "file:///#{base_image}"
          action :create_if_missing
        end

        template meta_data_file do
          cookbook 'atomic'
          source 'meta-data.erb'
          variables(
            node_name: new_resource.node_name,
            hostname: new_resource.node_name
          )
          action :create_if_missing
        end

        template user_data_file do
          cookbook 'atomic'
          source 'user-data.erb'
          variables({
            role: role,
            ssh_keys: ssh_keys,
            password: password
          })
          action :create_if_missing
        end

        execute "generate #{init_iso}" do
          command "genisoimage -output #{init_iso} -volid cidata -joliet -rock #{meta_data_file} #{user_data_file}"
          action :run
          not_if { ::File.exists?(init_iso) }
        end

        execute "#{new_resource.node_name} DHCP reservation" do
          command %Q{virsh net-update default add ip-dhcp-host '<host mac="#{mac_address}" ip="#{ip_address}"/>' --live --config}
          action :run
          not_if "virsh net-dumpxml default | grep #{ip_address} >/dev/null 2>&1"
        end

        cmd = []
        cmd << "virt-install --connect qemu:///system"
        cmd << "--name #{new_resource.node_name}"
        cmd << "--vcpus #{new_resource.cpus}"
        cmd << "--ram #{new_resource.ram}"
        cmd << "--os-type=linux"
        cmd << "--os-variant=fedora21"
        cmd << "--disk path=#{node_disk_file},device=disk,format=qcow2"
        cmd << "--disk path=#{init_iso},device=cdrom"
        cmd << "--network bridge=virbr0,mac=#{mac_address}"
        cmd << "--graphics vnc,listen=0.0.0.0 --noautoconsole"
        cmd << "--accelerate"
        cmd << "--import"

        execute "#{new_resource.node_name} virt-install" do
          command cmd.join(' ')
          action :run
          not_if "virsh dumpxml #{new_resource.node_name}"
        end

        ruby_block "#{new_resource.node_name} verify ssh" do
          block do
            cmd = Mixlib::ShellOut.new("ssh -i #{atomic_ssh_key} -o ConnectTimeout=2 -o PasswordAuthentication=no root@#{ip_address} uptime")
            succeeded = false
            10.times do
              cmd.run_command
              if ! cmd.error?
                succeeded = true
                break
              end
              sleep 5
            end

            unless succeeded
              raise RuntimeError, "Unable to successfully connect to #{ip_address} via ssh"
            end
          end
          action :run
        end

        if role == :master
          atomic_service "#{ip_address} local-registry" do
            unit_name 'local-registry'
            ip_address ip_address
            identity_file atomic_ssh_key
            template_name 'systemd-local-registry.erb'
            action [ :enable, :start ]
          end

          atomic_service "#{ip_address} etcd" do
            unit_name 'etcd'
            ip_address ip_address
            identity_file atomic_ssh_key
            template_name 'systemd-etcd.erb'
            action [ :enable, :start ]
          end
        end
      end
    end
  end
end
