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

remote_image = "#{node['atomic']['image_base_uri']}/#{node['atomic']['image_version']}"
compressed_image_file = "#{node['atomic']['work_dir']}/#{node['atomic']['image_version']}"
image_file = compressed_image_file.sub('qcow2.xz', 'qcow2')

%w(genisoimage libvirt.x86_64 libguestfs-tools qemu-kvm libvirt virt-install
   bridge-utils vnc xauth virt-manager kubernetes).each do |pkg|
  package pkg do
    action :install
  end
end

directory node['atomic']['work_dir'] do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

remote_file compressed_image_file do
  source remote_image
  owner 'root'
  group 'root'
  mode '0755'
  action :create_if_missing
  not_if { ::File.exist?(image_file) }
end

execute 'uncompress the qcow2 image' do
  command "xz -d #{compressed_image_file}"
  creates image_file
  action :run
end

service 'libvirtd' do
  supports status: true, restart: true, truereload: true
  action [:enable, :start]
end

execute 'generate atomic ssh key' do
  command "ssh-keygen -t rsa -b 2048 -f #{node['atomic']['work_dir']}/atomic_ssh_key -N ''"
  creates "#{node['atomic']['work_dir']}/atomic_ssh_key"
  action :run
end

directory '/root/.ssh' do
  owner 'root'
  group 'root'
  mode '0700'
  action :create
end

template '/root/.ssh/config' do
  source 'root-ssh-config.erb'
  owner 'root'
  group 'root'
  mode '0600'
  action :create
end
