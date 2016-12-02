require 'spec_helper'

describe package('epel-release'), :if => os[:family] == 'redhat' do 
  it { should be_installed }
end 