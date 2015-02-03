require 'spec_helper'

describe CodeWeb::MethodCall do
  subject { described_class }
  it "should compare" do
    expect(meth('puts', ['a', 'b'])).to eq(meth('puts',['a','b'], false, ['sample.rb']))
  end

  describe "#args?" do
    it { expect(meth("method", nil)).not_to be_args}
    it { expect(meth("method", [])).not_to be_args}
    it { expect(meth("method", [:a])).to be_args}
    it { expect(meth("method", [:a => 'a'])).to be_args}
  end

  describe "#yields?" do
    it { expect(meth("method", [], false)).not_to be_yield }
    it { expect(meth("method", [], true)).to be_yield }
  end

  describe "#method_types" do
    it { expect(meth("method", [%w(a b), {'a' => 'b'}, nil, :a, 'b']).method_types).to eq(%w([] {} nil : str)) }
  end

  describe "#small_signature" do
    it { expect(meth("method", [%w(a b)]).small_signature).to eq(["[]", 1]) }
    it { expect(meth("method", [[], [], []]).small_signature).to eq(["[]", 3]) }
    it { expect(meth("method", [{}, []]).small_signature).to eq(["{}", 2]) }
    it { expect(meth("method", []).small_signature).to eq(["nil", 0]) }
  end

  describe "#signature" do
    it { expect(meth("method", [%w(a b)]).signature).to eq("method(a, b)") }
    #it { expect(meth("method", [[], [], []]).signature).to eq("method([],[],[])")}
    # it { expect(meth("method", [{}, []]).signature).to eq("method({})") }
    # it { expect(meth("method", []).signature).to eq("method(nil)") }
    # it { expect(meth("method", [%w(a b), :other, :a => b]).signature).to eq("method(a, b)") }
  end

  context "sorted_args" do
    it "should not tack on [] to base args" do
      expect(meth('name',['a','b']).sorted_args.to_s).to eq('a, b')
    end

    it "should handle sub arrays" do
      expect(meth.sorted_hash(['b']).to_s).to eq('["b"]')
    end

    it "should handle hash" do
      expect(meth.sorted_hash(b:5, a:3).to_s).to eq('{:a=>3, :b=>5}')
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

  def meth(name = "method", args=[], is_yield=false, source = "file1", line = 5)
    CodeWeb::MethodCall.new(source, line, name, args, is_yield)
  end
end
