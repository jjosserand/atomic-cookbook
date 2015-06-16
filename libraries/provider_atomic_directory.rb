class Chef
  class Provider
    class AtomicDirectory < Chef::Provider::LWRPBase
      use_inline_resources

      def whyrun_supported?
        true
      end

      provides :atomic_directory

      include AtomicHelpers

      action :create do
        commands = [
          "mkdir -p #{new_resource.path}",
          "chown #{new_resource.owner}:#{new_resource.group} #{new_resource.path}"
        ]
        commands.each do |command|
          converge_by(%Q{run "#{command}" on #{new_resource.ip_address} via ssh}) do
            run_cmd_on_atomic_host!(new_resource.ip_address, command)
          end
        end
      end
    end
  end
end
