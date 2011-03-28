require File.expand_path('../spec_helper', __FILE__)

describe "Trinidad::Extensions::Resque::ResqueLifecycleListener" do
  R = Trinidad::Extensions::Resque::ResqueLifecycleListener

  it "configures workers with the task 'resque:work'" do
    task = configure_with_opts({})
    task.should == 'resque:work'
  end

  it "sets the name of the queues in the environment variable" do
    configure_with_opts({:queues => 'test'})
    ENV['QUEUES'].should == 'test'
  end

  it "sets the redis host name" do
    r = ::Resque.expects(:"redis=").with('localhost:6359')
    configure_with_opts({:redis_host => 'localhost:6359'})
  end

  it "sets the number of workers with the option :count" do
    task = configure_with_opts({:count => 3})
    ENV['COUNT'].should == '3'
    task.should == 'resque:workers'
  end

  it "loads the setup script with the option :setup" do
    configure_with_opts({:setup => File.expand_path('../resque_test_setup.rb', __FILE__)})
    Rake::Task['test:setup'].should be_instance_of(Rake::Task)
  end

  it "invokes the rake task given its name" do
    Rake::Task.any_instance.expects(:invoke)
    listener = R.new({})
    listener.invoke_workers('resque:work')
  end

  it "does not try to shut the workers down when it could not connect with Redis" do
    Rake::Task.any_instance.expects(:invoke).raises(Errno::ECONNREFUSED)
    ::Resque.expects(:workers).never

    listener = R.new({})
    listener.invoke_workers('resque:work')
    listener.stop_workers
  end

  it "invokes the shutdown! method for each worker before stopping the host" do
    m = mock
    m.expects(:shutdown!)
    ::Resque.expects(:workers).returns([m])

    listener = R.new({})
    listener.stop_workers
  end

  def configure_with_opts(options)
    listener = R.new(options)
    listener.configure_workers
  end
end
