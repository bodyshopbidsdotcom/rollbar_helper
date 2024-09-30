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

  class << self
    LEVELS.each do |level|
      define_method(level) do |*args|
        message, exception, extra = extract_arguments(args)
        extra = {callee: caller}.merge(extra)
        data, exception, callee, fingerprint = split_extra_arg(extra, exception)

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
      send(level, {callee: caller}, *args)
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
