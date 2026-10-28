require 'rollbar'
require 'rollbar_helper/version'

module RollbarHelper
  LEVELS = [
    :debug,
    :info,
    :warning,
    :error,
    :critical,
  ].freeze

  LEVELS_TO_LOGGER = {
    debug: :debug,
    info: :info,
    warning: :warn,
    error: :error,
    critical: :fatal
  }.freeze

  class << self
    LEVELS.each do |level|
      define_method(level) do |*args|
        message, exception, extra = extract_arguments(args)
        extra = { callee: caller }.merge(extra)
        data, exception, callee, fingerprint = split_extra_arg(extra, exception)

        call_custom_log(level, message, exception, callee, data) if custom_log?

        if !message.nil? && exception.nil?
          exception = StandardError.new(message).tap do |e|
            e.set_backtrace(callee)
          end
          message = nil
        end

        get_notifier(fingerprint).public_send(level, message, exception, data)
      end
    end

    def log(level, *args)
      raise ArgumentError, 'Log level is not supported' unless LEVELS.include?(level.to_sym)
      send(level, { callee: caller }, *args)
    end

    # Registers a block called on every report, before it is sent to Rollbar.
    # Calling it without a block removes the hook.
    def custom_log(&block)
      @custom_log = block
    end

    def custom_log?
      !@custom_log.nil?
    end

    private

    def call_custom_log(level, message, exception, callee, extra)
      @custom_log.call(
        loglevel: level,
        message: message,
        exception: exception,
        backtrace: exception&.backtrace || callee,
        extra: extra.dup
      )
    rescue StandardError => e
      # Logging failures must never prevent the underlying Rollbar report.
      # $stderr directly, since Kernel#warn is silent when $VERBOSE is nil.
      $stderr.puts("RollbarHelper custom_log failed to log: #{e.class}: #{e.message}")
    end

    def extract_arguments(args)
      message = exception = nil
      extra = {}

      args.each do |arg|
        if arg.is_a?(String)
          message = arg
        elsif arg.is_a?(Exception)
          exception = arg
        elsif arg.is_a?(Hash)
          extra = extra.merge(arg)
        end
      end

      [message, exception, extra]
    end

    def split_extra_arg(extra, exception)
      exception ||= extra.delete(:e) # Core legacy support
      callee = extra.delete(:callee)
      fingerprint = extra.delete(:fingerprint)
      [extra, exception, callee, fingerprint]
    end

    def get_notifier(fingerprint)
      return Rollbar if fingerprint.nil?
      Rollbar.scope(fingerprint: fingerprint)
    end
  end
end
