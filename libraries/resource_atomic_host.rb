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
      attribute :role,        kind_of: [String, Symbol], default: 'master'
      attribute :master_ip,   kind_of: String, default: nil
      attribute :node_ips,    kind_of: Array, default: []
    end
  end
end
