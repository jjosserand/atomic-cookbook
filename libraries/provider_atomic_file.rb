class Chef
  class Provider
    class AtomicFile < Chef::Provider::LWRPBase
      provides :atomic_file

      use_inline_resources

      def whyrun_supported?
        true
      end

      include AtomicHelpers

      action :create do
        local_file = atomic_file_local_path(new_resource.ip_address, new_resource.remote_file)

        template local_file do
          cookbook 'atomic'
          source new_resource.template_name
          action :create
        end

        ruby_block "#{new_resource.ip_address} #{new_resource.remote_file} send" do
          block do
            scp_to_atomic_host(
              new_resource.ip_address,
              local_file,
              new_resource.remote_file
            )
          end
          action :run
          only_if { file_diff_on_atomic_host?(new_resource.ip_address, new_resource.remote_file) }
        end
      end
    end
  end
end
