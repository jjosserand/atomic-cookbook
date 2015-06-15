include_recipe 'atomic'

atomic_host 'master' do
  ip_address '192.168.122.50'
  role :master
  action :create
end
