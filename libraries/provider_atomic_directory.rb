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
