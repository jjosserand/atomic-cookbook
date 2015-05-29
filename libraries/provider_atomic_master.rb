require 'chef/provider/lwrp_base'

class Chef
  class Provider
    class AtomicMaster < Chef::Provider::LWRPBase
      use_inline_resources

      def whyrun_supported?
        true
      end

      action :create do
        base_image = ::File.join(node['atomic']['work_dir'], node['atomic']['image_version']).sub('qcow2.xz', 'qcow2')
        init_iso = "#{node['atomic']['work_dir']}/#{new_resource.instance_id}/init.iso"
        resource_dir = "#{node['atomic']['work_dir']}/#{new_resource.instance_id}"
        meta_data_file = "#{resource_dir}/meta-data"
        user_data_file = "#{resource_dir}/user-data"

        directory resource_dir do
          owner 'root'
          group 'root'
          mode '0755'
          action :create
        end

        template meta_data_file do
          cookbook 'atomic'
          source 'meta-data.erb'
          variables atomic: node['atomic'].to_h
          notifies :run, "execute[generate #{init_iso}]"
          action :create
        end

        template user_data_file do
          cookbook 'atomic'
          source 'user-data.erb'
          variables atomic: node['atomic'].to_h
          notifies :run, "execute[generate #{init_iso}]"
          action :create
        end

        execute "generate #{init_iso}" do
          command "genisoimage -output #{init_iso} -volid cidata -joliet -rock #{meta_data_file} #{user_data_file}"
          action :run
        end

        execute "launch #{new_resource.instance_id}" do
          command "virt-install --connect qemu:///system --ram #{new_resource.ram} -n #{new_resource.instance_id} --os-type=linux --os-variant=rhel7 --disk path=#{base_image},device=disk,format=qcow2 --vcpus=#{new_resource.cpus} --disk path=#{init_iso} --import"
          action :run
        end
      end
    end
  end
end
