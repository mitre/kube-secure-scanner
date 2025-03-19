# encoding: utf-8
# copyright: 2023

title 'Container Process Checks'

control 'container-2.1' do
  impact 0.7
  title 'Check running processes'
  desc 'Verify expected processes are running'
  
  describe processes('sleep') do
    its('entries.length') { should be >= 1 }
    its('users') { should_not include 'root' }
  end
end

control 'container-2.2' do
  impact 0.5
  title 'Check for unexpected processes'
  desc 'Container should not run unexpected processes'
  
  describe processes('sshd') do
    its('entries.length') { should eq 0 }
  end
  
  %w(httpd nginx apache2).each do |svc|
    describe processes(svc) do
      its('entries.length') { should eq 0 }
    end
  end
end