require "spec_helper"
require "duckly"

describe Duckly do
  let!(:credentials){ {email: ENV["DUCK_UID"], password: ENV["DUCK_PWD"]} }

  context "gem specific" do
    subject { Duckly }
    it { subject::VERSION.should_not be_nil }
  end

  context "authentication process", :vcr do
    it { Duckly.new(credentials).should be_authenticated }
    it { Duckly.new(uid: credentials[:email], pwd: credentials[:password]).should be_authenticated }

    it "raises SecurityError on initialize" do
      expect { Duckly.new({email:"ddd@ddd.si"}) }.to raise_error Duckly::SecurityError
    end

    it "raises SecurityError on method call" do
      expect { Duckly.new({email:"ddd@ddd.si"}).me }.to raise_error Duckly::SecurityError
    end
  end

  context "has some methods", :vcr do
    subject { Duckly.new }
    it { should respond_to :tickets, :me }

  #  it { Duckly.new(credentials).me["Skype"].should match /zverchi/i }
  #  it { (d = Duckly.new(credentials)).tickets("utelier").should be_kind_of Array }
  end

end

