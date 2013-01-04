require "spec_helper"
require "../rubyProjects/TestRspec"

describe TestRspec do
  it "is named bhanu" do
    test = TestRspec.new
    test.name.should == "Bhanu"
  end
end