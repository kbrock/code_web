require 'spec_helper'

describe CodeWeb::MethodCall do
  it "should compare" do
    expect(meth('puts', ['a', 'b'])).to eq(meth('puts',['a','b'], false, ['sample.rb']))
  end

  it "should not tack on [] to base args" do
    expect(meth('name',['a','b']).sorted_args).to eq('a, b')
  end

  it "should handle sub arrays" do
    expect(subject.sorted_hash(['b'])).to eq('[b]')
  end

  it "should handle hash" do
    expect(subject.sorted_hash(b:5, a:3)).to eq('a:3, b:5')
  end

  private

  def meth(name, args=[], is_yield=false, source = nil)
    CodeWeb::MethodCall.new(source, name, Array(args), is_yield)
  end
end
