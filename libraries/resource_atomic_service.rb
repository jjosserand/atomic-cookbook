require 'chef/resource/lwrp_base'

class Chef
  class Resource
    class AtomicService < Chef::Resource::LWRPBase
      self.resource_name = :atomic_service
      actions :enable, :disable, :start, :stop
      default_action :enable

      attribute :unit_name,     kind_of: String, required: true
      attribute :ip_address,    kind_of: String, required: true
      attribute :template_name, kind_of: String
    end
  end
end
