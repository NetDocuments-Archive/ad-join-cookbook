require 'spec_helper'

describe user('Administrator') do
  it { should exist }
end
describe user('Administrator') do
  it { should belong_to_group 'administrators' }
end
