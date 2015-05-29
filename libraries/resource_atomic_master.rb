require 'chef/resource/lwrp_base'

class Chef
  class Resource
    class AtomicMaster < Chef::Resource::LWRPBase
      self.resource_name = :atomic_master
      actions :create
      default_action :create

      attribute :instance_id, kind_of: String, required: true, name_attribute: true
      attribute :hostname, kind_of: String, required: true
      attribute :password, kind_of: String, required: true
      attribute :ssh_keys, kind_of: Array, default: []
    end
  end
end
