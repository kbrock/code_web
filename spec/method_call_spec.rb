require 'spec_helper'

describe CodeWeb::MethodCall do
  it "should compare" do
    expect(meth('puts', ['a', 'b'])).to eq(meth('puts',['a','b'], false, ['sample.rb']))
  end

  context "sorted_args" do
    it "should not tack on [] to base args" do
      expect(meth('name',['a','b']).sorted_args.to_s).to eq('a, b')
    end

    it "should handle sub arrays" do
      expect(subject.sorted_hash(['b']).to_s).to eq('["b"]')
    end

    it "should handle hash" do
      expect(subject.sorted_hash(b:5, a:3).to_s).to eq('{:a=>3, :b=>5}')
    end
  end

  context "method_type" do
    # a string, a constant - same thing
    it "should handle strings" do
      expect(meth('name',['a']).method_types).to eq(['str'])
    end
    it "should handle arrays and hashes" do
      expect(meth('name',[['a','b'], {'a' => 5}, 'x']).method_types).to eq(['[]','{}','str'])
    end
  end

  private

  def meth(name, args=[], is_yield=false, source = nil)
    CodeWeb::MethodCall.new(source, name, Array(args), is_yield)
  end
end
