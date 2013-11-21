require 'spec_helper'

#$debug=true
#$verbose=true
describe CodeWeb::CodeParser do

  context "method call" do
    it 'should add a method' do
      subject.add_method("puts", ['"x"'], false )
      expect(method_calls('puts')).to eq([
        meth('puts',['"x"'])
      ])
    end

    it 'should support basic method call' do
      parse %{puts}
      expect(method_calls('puts')).to eq([
        meth('puts',[])
      ])
    end

    it 'should support method call with arguments' do
      parse %{puts "x", :y, true, false}
      expect(method_calls('puts')).to eq([
        meth('puts',['"x"', :y, :true, :false])
      ])
    end

    it 'should support method calls with hash arguments' do
      parse %{puts(a:5, "b" => 3)}
      expect(method_calls('puts')).to eq([
        meth('puts',{:a => 5, "b" => 3})
        ])
    end

    it 'should support method call ob objects' do
      parse %{y.puts "x"}
      expect(method_calls('y.puts')).to eq([
        meth('y.puts',['"x"'])
      ])
    end

    #NOTE the chaining isn't perfect
    it "should support method chaining" do
      parse "x(a:5).y().z(5)"
      expect(method_calls('x')).to eq([
        meth('x', [{a:5}])
      ])

      expect(method_calls('x(...).y')).to eq([
        meth('x(...).y')
      ])

      expect(method_calls('x(...).y.z')).to eq([
        meth('x(...).y.z',[5])
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
  end

  context 'blocks' do
    it 'should support if blocks' do
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

    it 'should support yield blocks' do
      parse "a(5) { |x| b(x) }"
      expect(method_calls('a')).to eq([
        meth('a',[5])
      ])
      expect(method_calls('b')).to eq([
        meth('b',[:x])
      ])
    end

    it 'should support rescue blocks' do
      parse %{
        begin
          a(5)
        rescue => e
          b(5)
        ensure
          c()
        end
      }
      expect(method_calls('a')).to eq([
        meth('a',[5])
      ])
      expect(method_calls('b')).to eq([
        meth('b',[5])
      ])
      expect(method_calls('c')).to eq([
        meth('c')
      ])
    end

    it 'should support rescue blocks' do
      parse "begin ; a(5) ; rescue ; b(5) ; end"
      expect(method_calls('a')).to eq([
        meth('a',[5])
      ])
      expect(method_calls('b')).to eq([
        meth('b',[5])
      ])
    end

    it 'should support rescue inline' do
      parse "a(5) rescue b(5)"
      expect(method_calls('a')).to eq([
        meth('a',[5])
      ])
      expect(method_calls('b')).to eq([
        meth('b',[5])
      ])
    end
  end

  context 'variables' do
    it "should support global variables" do
      parse %{$x=puts}
      expect(method_calls('puts')).to eq([
        meth('puts')
        ])
    end
    it "should support global variable fetch" do
      parse %{$x = puts}
      expect(method_calls('puts')).to eq([
        meth('puts')
      ])
    end
    it "should support constants" do
      parse %{
        ABC=puts
        Class::ABC.runx
      }
      expect(method_calls('puts')).to eq([
        meth('puts')
      ])
      expect(method_calls('Class.ABC.runx')).to eq([
        meth('Class.ABC.runx')
      ])
    end
  end

  it 'should parse modules' do
    parse %{
      module X
        ABC=abc()
        def method1
          @module_var=mod1()
        end
        def method2
          @@module_var=mod2()
        end
        def method3
          return mod3()
        end
      end
    }
    expect(method_calls('abc')).to eq([
      meth('abc')
    ])
    expect(method_calls('mod1')).to eq([
      meth('mod1')
    ])
    expect(method_calls('mod2')).to eq([
      meth('mod2')
    ])
    expect(method_calls('mod3')).to eq([
      meth('mod3')
    ])

  end
  it 'should support class' do
    parse %{
      module X
        attr_accessor :var
        class Class1
          def method1
            @var=m1(5)
          end
        end
        class Class2 < Class1
          def method2
            var=m2()
          end
        end
      end
    }
    expect(method_calls('m1')).to eq([
      meth('m1',[5])
    ])
    expect(method_calls('m2')).to eq([
      meth('m2')
    ])
  end

  it "should interpolate strings" do
    parse 'puts "abc#{subf()}"'
    expect(method_calls('subf')).to eq([
      meth('subf')
    ])
  end

  it "should support logic" do
    parse 'a() && b() || c() and d() or e()'
    %w(a b c d e).each do |method_name|
      expect(method_calls(method_name)).to eq([
        meth(method_name)
      ])
    end
  end

  private

  def method_calls(method_name=nil)
    if method_name
      subject.method_calls[method_name] 
    else
      subject.method_calls
    end
  end

  def parse(body, require_string=nil)
    test_method_name = caller[0].split('/').last.split(':')[0..1].join(':')
    subject.parse(test_method_name, body, require_string)
  end

  def meth(name, args=[], is_yield=false, source = nil)
    args = [args] unless args.is_a?(Array)
    CodeWeb::MethodCall.new(source, name, args, is_yield)
  end
end
