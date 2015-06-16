class Chef
  class Resource
    class AtomicDirectory < Chef::Resource::LWRPBase
      self.resource_name = :atomic_directory
      actions :create
      default_action :create

      provides :atomic_directory

      attribute :ip_address, kind_of: String, required: true
      attribute :path,       kind_of: String, required: true
      attribute :owner,      kind_of: String, default: 'root'
      attribute :group,      kind_of: String, default: 'root'
    end
  end
end
