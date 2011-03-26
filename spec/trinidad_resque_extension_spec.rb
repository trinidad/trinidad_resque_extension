require File.expand_path('../spec_helper', __FILE__)

describe "Trinidad::Extensions::ResqueServerExtension" do
  subject { Trinidad::Extensions::ResqueServerExtension.new({}) }
  let(:tomcat) { Trinidad::Tomcat::Tomcat.new }

  context "without user options" do
    it "uses localhost:6379 as default redis installation" do
      subject.options[:redis_host].should == 'localhost:6379'
    end

    it "adds a default queue called 'trinidad_resque'" do
      subject.options[:queues].should == 'trinidad_resque'
    end

    it "enables the reque console" do
      subject.options[:disable_web].should be_nil
    end
  end

  it "add the resque listener to the tomcat's default host" do
    subject.add_resque_listener tomcat
    tomcat.host.find_lifecycle_listeners.should have(1).listener
  end

  it "creates an application context for the resque console" do
    context = find_resque_web
    context.should be_instance_of(Trinidad::Tomcat::StandardContext)
  end

  it "does not create the application context when the option :disable_web is true" do
    e = Trinidad::Extensions::ResqueServerExtension.new({:disable_web => true})
    e.configure tomcat
    tomcat.host.find_child('/resque').should be_nil
  end

  it "uses the rackup parameter to start the application" do
    find_web_app.init_params['rackup'].should =~ /Resque::Server.new/
  end

  it "uses resque gem directory as application base directory" do
    resque_path = Gem::GemPathSearcher.new.find('resque').full_gem_path
    find_web_app.web_app_dir.should =~ /^#{resque_path}/
  end

  def find_resque_web
    subject.init_resque_web tomcat
    tomcat.host.find_child('/resque')
  end

  def find_web_app
    context = find_resque_web
    listener = context.find_lifecycle_listeners.select {|l| l.is_a? Trinidad::Lifecycle::Default }.first
    listener.webapp
  end
end
