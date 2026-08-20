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
    attr_accessor :logger

    LEVELS.each do |level|
      define_method(level) do |*args|
        message, exception, extra = extract_arguments(args)
        extra = { callee: caller }.merge(extra)
        data, exception, callee, fingerprint = split_extra_arg(extra, exception)

        if logger?
          method_name = LEVELS_TO_LOGGER[level.to_sym]
          msg = [message]
          msg << "An error occurred: #{exception.message}\n#{exception.backtrace.join("\n")}" unless exception.nil?
          msg << extra.to_s if !extra.nil? && !extra&.empty? && extra.respond_to?(:to_s)
          logger.send(method_name, msg.compact.join("\n").strip)
        end

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

    def logger?
      !@logger.nil?
    end

    private

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
