require 'chef/resource/lwrp_base'

class Chef
  class Resource
    class AtomicHost < Chef::Resource::LWRPBase
      self.resource_name = :atomic_host
      actions :create
      default_action :create

      attribute :instance_id, kind_of: String, name_attribute: true, required: true
      attribute :hostname, kind_of: String, required: true
      attribute :password, kind_of: String, required: true
      attribute :ssh_keys, kind_of: Array, default: []
      attribute :ram, kind_of: [Integer, String], default: 2048
      attribute :cpus, kind_of: [Integer, String], default: 2
      attribute :role, kind_of: [String, Symbol], default: 'master'
      attribute :master_id, kind_of: String, default: nil
    end
  end
end
