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
    class AtomicHost < Chef::Resource::LWRPBase
      self.resource_name = :atomic_host
      actions :create
      default_action :create

      provides :atomic_host

      attribute :node_name,   kind_of: String, name_attribute: true, required: true
      attribute :ip_address,  kind_of: String, required: true
      attribute :password,    kind_of: String, required: false, default: nil
      attribute :ssh_keys,    kind_of: Array, default: []
      attribute :ram,         kind_of: [Integer, String], default: 2048
      attribute :cpus,        kind_of: [Integer, String], default: 2
      attribute :role,        kind_of: [String, Symbol], required: true
      attribute :master_ip,   kind_of: String, default: nil
      attribute :node_ips,    kind_of: Array, default: []

      attribute :flannel_network,       kind_of: String, default: '172.16.0.0/12'
      attribute :flannel_subnet_length, kind_of: [Integer, String], default: 24
      attribute :flannel_backend_type,  kind_of: String, default: 'vxlan'
    end
  end
end
