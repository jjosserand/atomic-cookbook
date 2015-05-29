require 'chef/provider/lwrp_base'

class Chef
  class Provider
    class AtomicMaster < Chef::Provider::LWRPBase
      use_inline_resources

      def whyrun_supported?
        true
      end

      action :create do
        template "#{node['atomic']['work_dir']}/#{new_resource.instance_id}/meta-data" do
          source 'meta-data.erb'
          variables atomic: node['atomic'].to_h
          notifies :run, "bash[geniso-#{new_resource.instance_id}]"
          action :create
        end

        template "#{node['atomic']['work_dir']}/#{new_resource.instance_id}/user-data" do
          source 'user-data.erb'
          variables atomic: node['atomic'].to_h
          notifies :run, "bash[geniso-#{new_resource.instance_id}]"
          action :create
        end

        execute "geniso-#{new_resource.instance_id}" do
          command ''
          action :nothing
        end

        execute 'inject the atomic iso' do
          command "virt-install --connect qemu:///system --ram 4024 -n rhel_64 --os-type=linux --os-variant=rhel7 --disk path=#{iso_file},device=disk,format=qcow2 --vcpus=2 --import"
          creates '/tmp/something'
          action :run
        end
      end
    end
  end
end
