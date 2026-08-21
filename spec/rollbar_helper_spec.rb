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

  describe '#logger' do
    let(:logger) { double('Logger', debug: nil, info: nil, warn: nil, error: nil, fatal: nil) }

    after(:each) { RollbarHelper.logger = nil }

    it 'is nil by default' do
      expect(RollbarHelper.logger).to be_nil
      expect(RollbarHelper.logger?).to eq(false)
    end

    it 'is used when configured' do
      RollbarHelper.logger = logger
      expect(RollbarHelper.logger?).to eq(true)
    end

    levels_to_logger = {
      debug: :debug,
      info: :info,
      warning: :warn,
      error: :error,
      critical: :fatal
    }

    levels_to_logger.each do |level, logger_method|
      it "forwards ##{level} to the logger's ##{logger_method}" do
        RollbarHelper.logger = logger
        expect(logger).to receive(logger_method).with(a_string_including('Oops!'))
        RollbarHelper.public_send(level, 'Oops!', data)
      end
    end

    it 'includes the exception message and backtrace when present' do
      RollbarHelper.logger = logger
      exception = StandardError.new('Boom')
      exception.set_backtrace(['line 1', 'line 2'])

      expect(logger).to receive(:error) do |msg|
        expect(msg).to include('Oops!')
        expect(msg).to include('An error occurred: Boom')
        expect(msg).to include("line 1\nline 2")
      end

      RollbarHelper.error('Oops!', exception, data)
    end

    it 'does not blow up when the exception has no backtrace' do
      RollbarHelper.logger = logger
      exception = StandardError.new('Boom')

      expect(logger).to receive(:error) do |msg|
        expect(msg).to include('no backtrace available')
      end

      expect { RollbarHelper.error('Oops!', exception, data) }.not_to raise_error
    end

    it 'includes extra data when present' do
      RollbarHelper.logger = logger
      expect(logger).to receive(:error).with(a_string_including('Extra:'))
      RollbarHelper.error('Oops!', data)
    end

    it 'omits the extra section when there is no extra data' do
      RollbarHelper.logger = logger
      expect(logger).to receive(:error) do |msg|
        expect(msg).not_to include('Extra:')
      end
      RollbarHelper.error('Oops!')
    end

    it 'still reports to Rollbar even if the logger call raises' do
      RollbarHelper.logger = logger
      allow(logger).to receive(:error).and_raise(StandardError.new('logger exploded'))

      expect(Rollbar).to receive(:error).with(nil, instance_of(StandardError), data).and_call_original
      expect_any_instance_of(Rollbar::Item).to receive(:build_backtrace_body).and_call_original

      expect { RollbarHelper.error('Oops!', data) }.not_to raise_error
    end

    it 'does not call the logger when none is configured' do
      expect(Rollbar).to receive(:error).and_call_original
      expect_any_instance_of(Rollbar::Item).to receive(:build_backtrace_body).and_call_original
      expect { RollbarHelper.error('Oops!', data) }.not_to raise_error
    end
  end
end
