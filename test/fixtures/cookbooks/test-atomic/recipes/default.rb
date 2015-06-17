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

include_recipe 'atomic'

master = { 'name' => 'master', 'ip' => '192.168.122.50' }
nodes = [
  { 'name' => 'node1', 'ip' => '192.168.122.51' },
  { 'name' => 'node2', 'ip' => '192.168.122.52' }
]

# master host
atomic_host master['name'] do
  ip_address master['ip']
  node_ips nodes.map { |x| x['ip'] }
  role :master
  action :create
end

# node hosts
nodes.each do |node|
  atomic_host node['name'] do
    ip_address node['ip']
    master_ip master['ip']
    role :node
    action :create
  end
end

# directory to hold our kubernetes definitions
directory '/opt/kubernetes' do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
  action :create
end

template '/opt/kubernetes/pod-nginx.json' do
  source 'pod-nginx.json.erb'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

execute 'create nginx pod' do
  command 'kubectl create -f /opt/kubernetes/pod-nginx.json -s 192.168.122.50:8080'
  action :run
  not_if 'kubectl get pod nginx-id-01 -s 192.168.122.50:8080'
end

template '/opt/kubernetes/service-nginx.json' do
  source 'service-nginx.json.erb'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

execute 'create nginx service' do
  command 'kubectl create -f /opt/kubernetes/service-nginx.json -s 192.168.122.50:8080'
  action :run
  not_if 'kubectl get service nginx-service -s 192.168.122.50:8080'
end
