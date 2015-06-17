#
# Author:: Chef Partner Engineering (<partnereng@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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
        local_file = atomic_file_local_path(new_resource.target_ip_address, new_resource.remote_file)

        template local_file do
          cookbook 'atomic'
          source new_resource.template_name
          variables new_resource.variables
          action :create
        end

        ruby_block "#{new_resource.target_ip_address} #{new_resource.remote_file} send" do
          block do
            scp_to_atomic_host(
              new_resource.target_ip_address,
              local_file,
              new_resource.remote_file
            )
          end
          action :run
          only_if { file_diff_on_atomic_host?(new_resource.target_ip_address, new_resource.remote_file) }
        end
      end
    end
  end
end
