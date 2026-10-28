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

  describe '#custom_log' do
    let(:calls) { [] }

    before(:each) do
      RollbarHelper.custom_log do |loglevel:, message:, exception:, backtrace:, extra:|
        calls << { loglevel: loglevel, message: message, exception: exception, backtrace: backtrace, extra: extra }
      end
    end

    after(:each) { RollbarHelper.custom_log }

    it 'is not configured by default' do
      RollbarHelper.custom_log
      expect(RollbarHelper.custom_log?).to eq(false)
    end

    RollbarHelper::LEVELS.each do |level|
      it "is called for ##{level} with the Rollbar level" do
        RollbarHelper.public_send(level, 'Oops!', data)
        expect(calls.first).to include(loglevel: level, message: 'Oops!', exception: nil, extra: data)
      end
    end

    it "passes the caller's backtrace when there is no exception" do
      RollbarHelper.error('Oops!', data)
      expect(calls.first[:backtrace][0]).to include(__FILE__)
    end

    it "passes the exception and its backtrace when present" do
      exception = StandardError.new('Boom')
      exception.set_backtrace(['line 1', 'line 2'])
      RollbarHelper.error('Oops!', exception, data)
      expect(calls.first).to include(exception: exception, backtrace: ['line 1', 'line 2'])
    end

    it 'does not pass fingerprint or callee in extra' do
      RollbarHelper.error('Oops!', data, fingerprint: 'processor')
      expect(calls.first[:extra]).to eq(data)
    end

    it 'cannot alter the data sent to Rollbar' do
      RollbarHelper.custom_log { |extra:, **| extra[:injected] = true }
      expect(Rollbar).to receive(:error).with(nil, instance_of(StandardError), data).and_call_original
      RollbarHelper.error('Oops!', data)
    end

    it 'still reports to Rollbar even if the hook raises' do
      RollbarHelper.custom_log { |**| raise 'hook exploded' }
      expect(Rollbar).to receive(:error).with(nil, instance_of(StandardError), data).and_call_original
      expect { RollbarHelper.error('Oops!', data) }.to output(/hook exploded/).to_stderr
    end
  end
end
