# encoding: utf-8
# copyright: 2023

title 'Container User Checks'

control 'container-3.1' do
  impact 0.8
  title 'Container should not run as root'
  desc 'Containers should run as non-root users'
  
  describe command('whoami') do
    its('stdout.strip') { should_not eq 'root' }
  end
end

control 'container-3.2' do
  impact 0.6
  title 'Check user capabilities'
  desc 'Container users should have limited capabilities'
  
  only_if { command('which capsh').exit_status == 0 }
  
  describe command('capsh --print') do
    its('stdout') { should_not include 'cap_sys_admin' }
    its('stdout') { should_not include 'cap_net_admin' }
  end
end