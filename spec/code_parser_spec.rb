require 'spec_helper'

#$debug=true
#$verbose=true
describe CodeWeb::CodeParser do

  context "add method" do
    it 'should add a method' do
      subject.add_method("puts", ['"x"'], false )
      expect(method_calls('puts')).to eq([
        meth('puts',['"x"'])
      ])
    end
  end

  it 'should support basic method call' do
    parse %{puts}
    expect(method_calls('puts')).to eq([
      meth('puts',[])
    ])
  end

  it 'should support method call with arguments' do
    parse %{puts "x"}
    expect(method_calls('puts')).to eq([
      meth('puts',['"x"'])
    ])
  end

  it 'should support method call ob objects' do
    parse %{y.puts "x"}
    expect(method_calls('y.puts')).to eq([
      meth('y.puts',['"x"'])
    ])
  end

  #NOTE confused about this one
  it "should support method chaining" do
    parse "x().y().z(5)"

    expect(method_calls('x.y.z')).to eq([
      meth('x.y.z',[5])
    ])
  end

  it 'should support method calls with method calls' do
    parse "a(b(5))"
    expect(method_calls('b')).to eq([
      meth('b',[5])
    ])
    expect(method_calls('a')).to eq([
      meth('a','b(...)')
    ])
  end

  it 'should support method calls with if blocks' do
    parse "if a(5) ; b(5) ; else c(5) ; end"
    expect(method_calls('a')).to eq([
      meth('a',[5])
    ])
    expect(method_calls('b')).to eq([
      meth('b',[5])
    ])
    expect(method_calls('c')).to eq([
      meth('c',[5])
    ])
  end

  it 'should support method calls with yield blocks' do
    parse "a(5) { |x| b(x) }"
    expect(method_calls('a')).to eq([
      meth('a',[5])
    ])
    expect(method_calls('b')).to eq([
      meth('b',[:x])
    ])
  end


  it 'should support method calls within a module / class' do
    parse %{
      module X
        class Class1
          def method1
          end
        end
        class Class2 < Class1
          def method1
            a(5)
          end
        end
      end
    }
    expect(method_calls('a')).to eq([
      meth('a',[5])
    ])
  end

  private

  def method_calls(method_name)
    subject.method_calls[method_name]
  end

  def parse(body, require_string=nil)
    test_method_name = caller[0].split('/').last.split(':')[0..1].join(':')
    subject.parse(test_method_name, body, require_string)
  end

  def meth(name, args=[], is_yield=false, source = nil)
    CodeWeb::MethodCall.new(source, name, Array(args), is_yield)
  end
end
