require 'spec_helper'
require 'json'
describe "cluster status" do

  %w(master node1 node2).each do |host|
    it "#{host} host is running" do
      expect(command("virsh list").stdout).to match(/#{host}\s+running/)
    end
  end

  %w(192.168.122.51 192.168.122.52).each do |node|
    it "#{node} node is ready" do
      expect(command("kubectl -s 192.168.122.50:8080 get node #{node}").stdout).to match(/#{node}.*\sReady/)
    end
  end

  it 'about to sleep for 30 seconds to ensure the pod is running' do
  end

  it 'slept for 30 seconds... let us continue' do
    sleep 30
  end

  it 'has a running nginx pod' do
    pod = JSON.load(`kubectl get pod nginx-id-01 -s 192.168.122.50:8080 -o json`)
    expect(pod['status']['phase']).to eq "Running"
  end

  it 'has a configured nginx service' do
    expect(command('kubectl get service nginx-service -s 192.168.122.50:8080').exit_status).to eq 0
  end
end
