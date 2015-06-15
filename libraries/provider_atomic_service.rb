require 'chef/provider/lwrp_base'

class Chef
  class Provider
    class AtomicService < Chef::Provider::LWRPBase
      include AtomicHelpers

      use_inline_resources

      def whyrun_supported?
        true
      end


      action :enable do
        resource_dir  = ::File.join(node['atomic']['work_dir'], new_resource.ip_address)
        identity_file = ::File.join(@resource_dir, 'atomic_ssh_key')

        if !new_resource.template_file.nil?
          template "#{resource_dir}/systemd-#{new_resource.unit_name}" do
            source new_resource.template_name
            action :create
            notifies :run, "ruby_block[#{new_resource.ip_address} #{new_resource.unit_name} scp]", :immediately
            notifies :run, "ruby_block[#{new_resource.ip_address} reload systemd]", :immediately
          end

          ruby_block "#{new_resource.ip_address} #{new_resource.unit_name} scp" do
            block do
              scp_to_atomic_node(
                new_resource.ip_address,
                identity_file,
                "#{resource_dir}/systemd-#{new_resource.unit_name}",
                "/etc/systemd/system/#{new_resource.unit.name}.service"
              )
            end
            action :nothing
          end

          ruby_block "#{new_resource.ip_address} reload systemd" do
            block do
              run_cmd_on_atomic_node(ip_address, "systemctl daemon-reload")
            end
            action :nothing
          end
        end

        ruby_block "#{new_resource.ip_address} #{new_resource.unit_name} enable" do
          block do
            run_cmd_on_atomic_node(
              new_resource.ip_address,
              identity_file,
              "systemctl enable #{new_resource.unit_name}"
            )
          end
          action :run
        end
      end

      action :disable do
        resource_dir  = ::File.join(node['atomic']['work_dir'], new_resource.ip_address)
        identity_file = ::File.join(@resource_dir, 'atomic_ssh_key')
        
        ruby_block "#{new_resource.ip_address} #{new_resource.unit_name} enable" do
          block do
            run_cmd_on_atomic_node(
              new_resource.ip_address,
              identity_file,
              "systemctl disable #{new_resource.unit_name}"
            )
          end
          action :run
        end
      end

      action :start do
        resource_dir  = ::File.join(node['atomic']['work_dir'], new_resource.ip_address)
        identity_file = ::File.join(@resource_dir, 'atomic_ssh_key')

        ruby_block "#{new_resource.ip_address} #{new_resource.unit_name} enable" do
          block do
            run_cmd_on_atomic_node(
              new_resource.ip_address,
              identity_file,
              "systemctl start #{new_resource.unit_name}"
            )
          end
          action :run
        end
      end

      action :stop do
        resource_dir  = ::File.join(node['atomic']['work_dir'], new_resource.ip_address)
        identity_file = ::File.join(@resource_dir, 'atomic_ssh_key')

        ruby_block "#{new_resource.ip_address} #{new_resource.unit_name} enable" do
          block do
            run_cmd_on_atomic_node(
              new_resource.ip_address,
              identity_file,
              "systemctl stop #{new_resource.unit_name}"
            )
          end
          action :run
        end
      end
    end
  end
end
