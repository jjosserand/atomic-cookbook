compressed_iso_file = "#{node['atomic']['iso_base_uri']}/#{node['atomic']['iso_version']}"
iso_file = compressed_iso_file.sub('qcow2.xz', 'qcow2')

%w(genisoimage libvirt.x86_64 libguestfs-tools qemu-kvm libvirt virt-install bridge-utils).each do |pkg|
  package pkg do
    action :install
  end
end

directory node['atomic']['work_dir'] do
  owner 'root'
  group 'root'
  mode '0700'
  action :create
end

remote_file compressed_iso_file do
  source "#{node['atomic']['iso_base_uri']}/#{node['atomic']['iso_version']}"
end

execute 'uncompress the qcow2 iso' do
  command "xz -d #{compressed_iso_file}"
  creates iso_file
  action :run
end

service 'libvirtd' do
  supports status: true, restart: true, truereload: true
  action [:enable, :start]
end
