include_recipe 'atomic'

master = { name: 'master', ip: '192.168.122.50' }
nodes = [
  { name: 'node1', ip: '192.168.122.51' },
  { name: 'node2', ip: '192.168.122.52' }
]

# master host
atomic_host master[:name] do
  ip_address master[:ip]
  node_ips nodes.map { |x| x[:ip] }
  role :master
  action :create
end

# node hosts
nodes.each do |node|
  atomic_host node[:name] do
    ip_address node[:ip]
    master_ip master[:ip]
    role :node
    action :create
  end
end
