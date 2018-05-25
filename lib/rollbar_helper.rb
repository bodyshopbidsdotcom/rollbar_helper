class RollbarHelper
  VERSION = "0.1.0"

  class << self

    def error(obj, extra = {}, fingerprint: nil)
      e = nil

      if obj.is_a?(Exception)
        e = obj
      else
        e = StandardError.new(obj.to_s)
        e.set_backtrace(caller)
      end

      if fingerprint.present?
        Rollbar.scope(:fingerprint => fingerprint).error(e, **extra)
      else
        Rollbar.error(e, **extra)
      end
    end

  end
end
