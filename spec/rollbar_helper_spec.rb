require "spec_helper"

RSpec::Matchers.define :caller_backtrace do |expected|
  match do |actual|
    actual.backtrace[0].include?(expected)
  end
end

RSpec.describe RollbarHelper do
  let(:data) { {data: true} }

  before(:each) do
    allow_any_instance_of(Rollbar::Notifier).to receive(:enabled?).and_return(true)
    allow_any_instance_of(Rollbar::Configuration).to receive(:transmit).and_return(false)
  end


  it "has a version number" do
    expect(RollbarHelper::VERSION).not_to be nil
  end

  it 'responds to log level methods' do
    expect(RollbarHelper.respond_to?(:debug)).to    eq(true)
    expect(RollbarHelper.respond_to?(:info)).to     eq(true)
    expect(RollbarHelper.respond_to?(:warning)).to  eq(true)
    expect(RollbarHelper.respond_to?(:error)).to    eq(true)
    expect(RollbarHelper.respond_to?(:critical)).to eq(true)
  end

  it 'support sending both a message and an exception' do
    expect(Rollbar).to receive(:error).with('Oops!', instance_of(StandardError), data).and_call_original
    expect_any_instance_of(Rollbar::Item).to receive(:build_backtrace_body).and_call_original
    RollbarHelper.error('Oops!', StandardError.new('Error'), data)
  end

  context '#core legacy' do
    it 'support sending both a message and an exception' do
      expect(Rollbar).to receive(:error).with('Oops!', instance_of(StandardError), data).and_call_original
      expect_any_instance_of(Rollbar::Item).to receive(:build_backtrace_body).and_call_original
      RollbarHelper.error('Oops!', data.merge(e: StandardError.new('Error')))
    end
  end

  it 'wraps rollbar method with error' do
    expect(Rollbar).to receive(:error).with(nil, instance_of(StandardError), data).and_call_original
    expect_any_instance_of(Rollbar::Item).to receive(:build_backtrace_body).and_call_original
    RollbarHelper.error('Oops!', data)
  end

  it 'uses callers backtrace' do
    expect(Rollbar).to receive(:error).with(nil, caller_backtrace(__FILE__), data).and_call_original
    expect_any_instance_of(Rollbar::Item).to receive(:build_backtrace_body).and_call_original
    RollbarHelper.error('Oops!', data)
  end

  it 'scopes with fingerprint' do
    expect(Rollbar).to receive(:scope).with(fingerprint: 'processor').and_call_original
    expect_any_instance_of(Rollbar::Notifier).to receive(:error).with(nil, caller_backtrace(__FILE__), data).and_call_original
    expect_any_instance_of(Rollbar::Item).to receive(:build_backtrace_body).and_call_original
    RollbarHelper.error('Oops!', data, fingerprint: 'processor')
  end

  describe '#log' do
    it 'uses callers backtrace' do
      expect(Rollbar).to receive(:error).with(nil, caller_backtrace(__FILE__), data).and_call_original
      expect_any_instance_of(Rollbar::Item).to receive(:build_backtrace_body).and_call_original
      RollbarHelper.log(:error, 'Oops!', data)
    end

    it 'raises on unsupported log levels' do
      expect {
        RollbarHelper.log(:silly, 'Oops!', data)
      }.to raise_error(ArgumentError, 'Log level is not supported')
    end
  end
end
