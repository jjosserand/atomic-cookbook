require 'chef/provider/lwrp_base'

class Chef
  class Provider
    class AtomicService < Chef::Provider::LWRPBase
      use_inline_resources

      def whyrun_supported?
        true
      end

      include AtomicHelpers

      action :enable do
        command = "systemctl enable #{new_resource.unit_name}"
        converge_by(%Q{run "#{command}" on #{new_resource.ip_address} via ssh}) do
          run_cmd_on_atomic_host!(new_resource.ip_address, command)
        end
      end

      action :disable do
        command = "systemctl disable #{new_resource.unit_name}"
        converge_by(%Q{run "#{command}" on #{new_resource.ip_address} via ssh}) do
          run_cmd_on_atomic_host!(new_resource.ip_address, command)
        end
      end

      action :start do
        command = "systemctl start #{new_resource.unit_name}"
        converge_by(%Q{run "#{command}" on #{new_resource.ip_address} via ssh}) do
          run_cmd_on_atomic_host!(new_resource.ip_address, command)
        end
      end

      action :stop do
        command = "systemctl stop #{new_resource.unit_name}"
        converge_by(%Q{run "#{command}" on #{new_resource.ip_address} via ssh}) do
          run_cmd_on_atomic_host!(new_resource.ip_address, command)
        end
      end

      action :restart do
        command = "systemctl restart #{new_resource.unit_name}"
        converge_by(%Q{run "#{command}" on #{new_resource.ip_address} via ssh}) do
          run_cmd_on_atomic_host!(new_resource.ip_address, command)
        end
      end
    end
  end
end
