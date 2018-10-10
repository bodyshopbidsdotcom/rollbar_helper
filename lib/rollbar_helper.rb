require 'rollbar'

class RollbarHelper
  VERSION = "0.2.0"
  LEVELS = [
    :critical,
    :debug,
    :error,
    :info,
    :warning,
  ]

  class << self
    def critical(obj, fingerprint: nil, **data)
      log(:critical, obj, :callee => caller, fingerprint: fingerprint, **data)
    end

    def debug(obj, fingerprint: nil, **data)
      log(:debug, obj, :callee => caller, fingerprint: fingerprint, **data)
    end

    def error(obj, fingerprint: nil, **data)
      log(:error, obj, :callee => caller, fingerprint: fingerprint, **data)
    end

    def info(obj, fingerprint: nil, **data)
      log(:info, obj, :callee => caller, fingerprint: fingerprint, **data)
    end

    def warn(obj, fingerprint: nil, **data)
      log(:warning, obj, :callee => caller, fingerprint: fingerprint, **data)
    end

    def warning(obj, fingerprint: nil, **data)
      log(:warning, obj, :callee => caller, fingerprint: fingerprint, **data)
    end

    def log(level, obj, callee: caller, fingerprint: nil, **data)
      level = level.to_sym
      raise ArgumentError, 'Log level is not supported' unless LEVELS.include?(level)
      e = nil

      if obj.is_a?(Exception)
        e = obj
      else
        e = StandardError.new(obj.to_s)
        e.set_backtrace(callee)
      end

      unless fingerprint.nil?
        ::Rollbar.scope(:fingerprint => fingerprint).send(level, e, data)
      else
        ::Rollbar.send(level, e, data)
      end
    end
  end
end
