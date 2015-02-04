require 'spec_helper'

describe CodeWeb::MethodCache do
  describe "#<<" do
    context "with default regex" do
      it { expect(subject.method_calls).to be_empty }
      context "with method" do
        before { subject << methodcall }
        it { expect(subject.method_calls.size).to eq(1) }
      end
    end

    context "with regex" do
      subject { described_class.new(/good/)}
      context "with matching regex" do
        before { subject << methodcall("goodone") }
        it { expect(subject.method_calls.size).to eq(1) }
      end
      context "with non-matching regex" do
        before { subject << methodcall("badone") }
        it { expect(subject.method_calls.size).to eq(0) }
      end
    end
  end

  def methodcall(name = "method", args = [])
    CodeWeb::MethodCall.new("file.rb", 5, name, args)
  end
end
