require "spec_helper"

RSpec::Matchers.define :caller_backtrace do |expected|
  match do |actual|
    actual.backtrace[0].include?(expected)
  end
end

RSpec.describe RollbarHelper do
  it "has a version number" do
    expect(RollbarHelper::VERSION).not_to be nil
  end

  it 'responds to log level methods' do
    expect(RollbarHelper.respond_to?(:critical)).to eq(true)
    expect(RollbarHelper.respond_to?(:debug)).to eq(true)
    expect(RollbarHelper.respond_to?(:error)).to eq(true)
    expect(RollbarHelper.respond_to?(:info)).to eq(true)
    expect(RollbarHelper.respond_to?(:warning)).to eq(true)
  end

  it 'wraps rollbar method with error' do
    expect(Rollbar).to receive(:error).with(instance_of(StandardError), :data => true)
    RollbarHelper.error('Oops!', :data => true)
  end

  it 'uses callers backtrace' do
    expect(Rollbar).to receive(:error).with(caller_backtrace(__FILE__), :data => true)
    RollbarHelper.error('Oops!', :data => true)
  end

  it 'scopes with fingerprint' do
    expect(Rollbar).to receive(:scope).with(:fingerprint => 'processor').and_return(Rollbar)
    expect(Rollbar).to receive(:error).with(caller_backtrace(__FILE__), :data => true)
    RollbarHelper.error('Oops!', :fingerprint => 'processor', :data => true)
  end

  describe '#log' do
    it 'uses callers backtrace' do
      expect(Rollbar).to receive(:error).with(caller_backtrace(__FILE__), :data => true)
      RollbarHelper.log(:error, 'Oops!', :data => true)
    end

    it 'raises on unsupported log levels' do
      expect {
        RollbarHelper.log(:silly, 'Oops!', :data => true)
      }.to raise_error(ArgumentError, 'Log level is not supported')
    end
  end
end
