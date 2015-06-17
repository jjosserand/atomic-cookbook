require 'spec_helper'
require 'json'

describe 'cluster status' do
  %w(master node1 node2).each do |host|
    it "#{host} host is running" do
      expect(command('virsh list').stdout).to match(/#{host}\s+running/)
    end
  end

  %w(192.168.122.51 192.168.122.52).each do |node|
    it "#{node} node is ready" do
      expect(command("kubectl -s 192.168.122.50:8080 get node #{node}").stdout).to match(/#{node}.*\sReady/)
    end
  end

  it 'has a running nginx pod' do
    pod = JSON.load(`kubectl get pod nginx-id-01 -s 192.168.122.50:8080 -o json`)
    expect(pod['status']['phase']).to match(/Running|Pending/)
  end

  it 'has a configured nginx service' do
    expect(command('kubectl get service nginx-service -s 192.168.122.50:8080').exit_status).to eq 0
  end
end
