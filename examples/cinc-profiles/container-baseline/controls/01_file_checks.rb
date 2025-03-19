# encoding: utf-8
# copyright: 2023

title 'Container File Checks'

control 'container-1.1' do
  impact 0.7
  title 'Ensure sensitive files are protected'
  desc 'Critical files should have appropriate permissions'
  
  describe file('/etc/passwd') do
    it { should exist }
    it { should be_owned_by 'root' }
    its('mode') { should cmp '0644' }
  end
  
  describe file('/etc/shadow') do
    it { should exist }
    it { should be_owned_by 'root' }
    its('mode') { should cmp '0640' }
    it { should_not be_readable.by('others') }
  end
end

control 'container-1.2' do
  impact 0.5
  title 'Check for required files'
  desc 'Container should have the required files present'
  
  describe file('/etc/os-release') do
    it { should exist }
    its('content') { should match /VERSION/ }
  end
end