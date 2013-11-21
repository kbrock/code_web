require 'spec_helper'

describe CodeWeb::MethodCall do
  it "should compare" do
    expect(meth('puts', ['a', 'b'])).to eq(meth('puts',['a','b'], false, ['sample.rb']))
  end

  private

  def meth(name, args=[], is_yield=false, source = nil)
    CodeWeb::MethodCall.new(source, name, Array(args), is_yield)
  end
end
