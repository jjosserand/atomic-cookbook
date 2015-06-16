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
  not_if { ::File.exists?(image_file) }
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

template '/root/.ssh/config' do
  source 'root-ssh-config.erb'
  owner 'root'
  group 'root'
  mode '0600'
  action :create
end
