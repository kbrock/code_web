require 'spec_helper'

describe CodeWeb::MethodList do
  let(:four) { described_class.new(nil, [meth("a",%w(a b c)), meth("a",%w(a b)), meth("b",%w(a b)), meth("b",%w(a))]) }

  describe "#group_by" do
    subject { four.group_by(:name) }
    it { expect(four.group_by(:name).count).to eq(2) }
    it { expect(four.group_by(:name).map { |m| m.f.name }).to eq(%w(a b)) }
    it { expect(four.group_by(:args_size).map { |m| m.args_size }).to eq([1, 2, 3]) }
  end

  # "#group_by"
  #detect
  #each
  describe "#count" do
    it { expect(ml([meth("a"), meth("b")]).count).to eq(2) }
  end
  describe "#arg_keys" do
    it { expect(ml([meth("method", [{a:5, b:5, c:5}]), meth("method", [{d:5}])]).arg_keys).to eq([:a, :b, :c, :d]) }
  end

  private

  def ml(methods, name=nil)
    described_class.new(name, methods)
  end

  def meth(name = "method", args=[], is_yield=false, source = "file1", line = 5)
    CodeWeb::MethodCall.new(source, line, name, args, is_yield)
  end
end
