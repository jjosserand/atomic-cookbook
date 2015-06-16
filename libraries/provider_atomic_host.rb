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
        role        = new_resource.role.to_sym
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

        remote_file "#{ip_address} disk file" do
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

        execute "#{ip_address} DHCP reservation" do
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

        execute "#{ip_address} virt-install" do
          command cmd.join(' ')
          action :run
          not_if "virsh dumpxml #{new_resource.node_name}"
        end

        ruby_block "#{ip_address} verify ssh" do
          block do
            Chef::Log.info("#{ip_address} created, waiting for cloud-init to run and SSH to come up - please be patient...")
            succeeded = false
            60.times do |x|
              Chef::Log.info("Testing SSH on #{ip_address}, attempt #{x+1}")
              cmd = Mixlib::ShellOut.new("ssh -i #{atomic_ssh_key} -o ConnectTimeout=2 -o PasswordAuthentication=no root@#{ip_address} uptime")
              cmd.run_command
              if ! cmd.error?
                succeeded = true
                break
              end
              Chef::Log.info("#{ip_address} is not yet ready... waiting and retrying...")
              sleep 2
            end

            unless succeeded
              raise RuntimeError, "Unable to successfully connect to #{ip_address} via ssh"
            end
          end
          action :run
        end

        ruby_block "#{ip_address} systemd reload" do
          block do
            run_cmd_on_atomic_host!(ip_address, "systemctl daemon-reload")
          end
          action :nothing
        end

        if role == :master
          docker_cmd = []
          docker_cmd << "docker create -p 5000:5000"
          docker_cmd << "-v /var/lib/local-registry:/srv/registry"
          docker_cmd << "-e STANDALONE=false"
          docker_cmd << "-e MIRROR_SOURCE=https://registry-1.docker.io"
          docker_cmd << "-e MIRROR_SOURCE_INDEX=https://index.docker.io"
          docker_cmd << "-e STORAGE_PATH=/srv/registry"
          docker_cmd << "--name=local-registry registry"
          docker_cmd << "&& chcon -Rvt svirt_sandbox_file_t /var/lib/local-registry"

          ruby_block "#{ip_address} create local-registry container" do
            block do
              run_cmd_on_atomic_host!(ip_address, docker_cmd.join(' '), timeout_duration=300)
            end
            action :run
            not_if { cmd_on_atomic_host_success?(ip_address, "docker inspect local-registry") }
          end

          atomic_file "#{ip_address} systemd local-registry" do
            ip_address ip_address
            remote_file '/etc/systemd/system/local-registry.service'
            template_name 'systemd-local-registry.erb'
            action :create
            notifies :run, "ruby_block[#{ip_address} systemd reload]", :immediately
          end

          atomic_file "#{ip_address} systemd etcd" do
            ip_address ip_address
            remote_file '/etc/systemd/system/etcd.service'
            template_name 'systemd-etcd.erb'
            action :create
            notifies :run, "ruby_block[#{ip_address} systemd reload]", :immediately
          end

          atomic_file "#{ip_address} kubernetes config" do
            ip_address ip_address
            remote_file '/etc/kubernetes/config'
            template_name 'kubernetes-config.erb'
            variables Hash(master_ip_address: ip_address, role: role)
            action :create
            notifies :restart, "atomic_service[#{ip_address} kube-apiserver]"
            notifies :restart, "atomic_service[#{ip_address} kube-controller-manager]"
            notifies :restart, "atomic_service[#{ip_address} kube-scheduler]"
          end

          atomic_file "#{ip_address} kubernetes apiserver config" do
            ip_address ip_address
            remote_file '/etc/kubernetes/apiserver'
            template_name 'kubernetes-apiserver-config.erb'
            variables Hash(master_ip_address: ip_address)
            action :create
            notifies :restart, "atomic_service[#{ip_address} kube-apiserver]"
          end

          atomic_file "#{ip_address} kubernetes controller-manager config" do
            ip_address ip_address
            remote_file '/etc/kubernetes/controller-manager'
            template_name 'kubernetes-controller-manager-config.erb'
            variables Hash(node_ip_addresses: new_resource.node_ips)
            action :create
            notifies :restart, "atomic_service[#{ip_address} kube-controller-manager]"
          end

          atomic_directory "#{ip_address} /var/run/kubernetes" do
            ip_address ip_address
            path '/var/run/kubernetes'
            owner 'kube'
            action :create
          end

          %w(local-registry etcd kube-apiserver kube-controller-manager kube-scheduler).each do |svc|
            atomic_service "#{ip_address} #{svc}" do
              ip_address ip_address
              unit_name svc
              action [ :enable, :start ]
            end
          end

          flannel_config = {
            "Network" => new_resource.flannel_network,
            "SubnetLen" => new_resource.flannel_subnet_length.to_i,
            "Backend" => { "Type" => new_resource.flannel_backend_type }
          }
          flannel_etcd_url = "http://#{ip_address}:4001/v2/keys/atomic01/network/config"
          http_request "#{ip_address} flannel config" do
            action :put
            url flannel_etcd_url
            message "value=#{URI.escape(flannel_config.to_json)}"
            not_if "curl -f #{flannel_etcd_url}"
          end
        end # role == :master

        if role == :node
          atomic_file "#{ip_address} docker sysconfig" do
            ip_address ip_address
            remote_file '/etc/sysconfig/docker'
            template_name 'docker-sysconfig.erb'
            variables Hash(master_ip_address: new_resource.master_ip)
            action :create
            notifies :restart, "atomic_service[#{ip_address} docker]"
          end

          atomic_file "#{ip_address} flanneld sysconfig" do
            ip_address ip_address
            remote_file '/etc/sysconfig/flanneld'
            template_name 'flanneld-sysconfig.erb'
            variables Hash(master_ip_address: new_resource.master_ip)
            action :create
            notifies :restart, "atomic_service[#{ip_address} flanneld]"
          end

          atomic_directory "#{ip_address} docker.service.d" do
            ip_address ip_address
            path '/etc/systemd/system/docker.service.d'
            action :create
          end

          atomic_file "#{ip_address} docker systemd drop-in" do
            ip_address ip_address
            remote_file '/etc/systemd/system/docker.service.d/10-flanneld-network.conf'
            template_name 'systemd-docker.erb'
            action :create
            notifies :run, "ruby_block[#{ip_address} systemd reload]", :immediately
            notifies :restart, "atomic_service[#{ip_address} docker]"
          end

          atomic_file "#{ip_address} kubernetes config" do
            ip_address ip_address
            remote_file '/etc/kubernetes/config'
            template_name 'kubernetes-config.erb'
            variables Hash(master_ip_address: new_resource.master_ip)
            action :create
            notifies :restart, "atomic_service[#{ip_address} kubelet]"
            notifies :restart, "atomic_service[#{ip_address} kube-proxy]"
          end

          atomic_file "#{ip_address} kubelet config" do
            ip_address ip_address
            remote_file '/etc/kubernetes/kubelet'
            template_name 'kubernetes-kubelet.erb'
            variables Hash(node_ip_address: ip_address, master_ip_address: new_resource.master_ip)
            action :create
            notifies :restart, "atomic_service[#{ip_address} kubelet]"
            notifies :restart, "atomic_service[#{ip_address} kube-proxy]"
          end

          %w(docker flanneld kubelet kube-proxy).each do |svc|
            atomic_service "#{ip_address} #{svc}" do
              ip_address ip_address
              unit_name svc
              action [ :enable, :start ]
            end
          end
        end
      end
    end
  end
end
