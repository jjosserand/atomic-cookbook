include_recipe 'atomic'

atomic_master 'atomic-master' do
  hostname 'atomic-master'
  password 'p@$$w0rd'
  action :create
end

1.upto(3) do |id|
  atomic_minion "atomic-minion-#{id}" do
    hostname "atomic-minion-#{id}"
    password 'p@$$w0rd'
    master_id 'atomic-master'
    action :create
  end
end
