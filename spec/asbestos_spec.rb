require 'action_view'
require 'asbestos'

describe Asbestos::Builder do
  before do
    @json = described_class.new
  end
  
  def to_json
    @json.target!.to_json
  end
  
  it "should be empty hash" do
    to_json.should == '{}'
  end
  
  it "should add a key-value pair" do
    @json.foo('bar')
    to_json.should == '{"foo": "bar"}'
  end
  
  it "should add a key-value pair with `tag!`" do
    @json.tag!(:foo, 'bar')
    to_json.should == '{"foo": "bar"}'
  end
  
  it "should not cast numbers to strings" do
    @json.num(2)
    to_json.should == '{"num": 2}'
  end
  
  it "should case values to strings if there are more than one" do
    @json.num(2, 3)
    to_json.should == '{"num": "23"}'
  end
  
  it "should do nested hashes with block form" do
    @json.foo do
      @json.bar('baz')
      @json.qoo('qux')
    end
    to_json.should == '{"foo": {"bar": "baz", "qoo": "qux"}}'
  end
  
  it "should do nested hashes with block form and attributes" do
    @json.foo(:qoo => 'qux') do
      @json.bar('baz')
    end
    to_json.should == '{"foo": {"qoo": "qux", "bar": "baz"}}'
  end
  
  it "should ignore instruct" do
    @json.instruct!
    to_json.should == '{}'
  end
  
  it "should ignore instruct when used with attributes" do
    @json.instruct! :xml, :version => "1.0" 
    to_json.should == '{}'
  end
  
  it "should support ignores" do
    @json = described_class.new(:ignore => ['foo'])
    @json.foo do
      @json.bar('baz')
    end
    to_json.should == '{"bar": "baz"}'
  end
  
  it "should support aggregates" do
    @json = described_class.new(:aggregate => ['foo'])
    @json.foo do
      @json.bar('baz')
    end
    @json.foo do
      @json.bar('qux')
    end
    to_json.should == '{"foos": [{"bar": "baz"}, {"bar": "qux"}]}'
  end
end
