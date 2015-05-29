require 'chef/resource/lwrp_base'

class Chef
  class Resource
    class AtomicMaster < Chef::Resource::LWRPBase
      self.resource_name = :atomic_master
      actions :create
      default_action :create

      attribute :instance_id, kind_of: String, name_attribute: true, required: true
      attribute :hostname, kind_of: String, required: true
      attribute :password, kind_of: String, required: true
      attribute :ssh_keys, kind_of: Array, default: []
      attribute :ram, kind_of: [Integer, String], default: 2048
      attribute :cpus, kind_of: [Integer, String], default: 2
    end
  end
end
