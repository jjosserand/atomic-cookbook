include_recipe 'atomic'

atomic_host node['test-atomic']['instance_id'] do
  role node['test-atomic']['role']
  master_id node['test-atomic']['master_id']
  hostname node['test-atomic']['instance_id']
  password node['test-atomic']['password']
  action :create
end
