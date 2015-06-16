class Chef
  class Resource
    class AtomicFile < Chef::Resource::LWRPBase
      self.resource_name = :atomic_file
      actions :create
      default_action :create

      provides :atomic_file

      attribute :remote_file,   kind_of: String, required: true
      attribute :template_name, kind_of: String, required: true
      attribute :ip_address,    kind_of: String, required: true
      attribute :variables,     kind_of: Hash,   default: {}
    end
  end
end
