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
  class Resource
    class AtomicService < Chef::Resource::LWRPBase
      self.resource_name = :atomic_service
      actions :enable, :disable, :start, :stop
      default_action :enable

      attribute :unit_name,     kind_of: String, required: true
      attribute :ip_address,    kind_of: String, required: true
      attribute :template_name, kind_of: String
    end
  end
end
