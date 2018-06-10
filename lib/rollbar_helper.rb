class RollbarHelper
  VERSION = "0.2.0"

  class << self

    def error(obj, fingerprint: nil, **data)
      e = nil

      if obj.is_a?(Exception)
        e = obj
      else
        e = StandardError.new(obj.to_s)
        e.set_backtrace(caller)
      end

      if fingerprint.present?
        Rollbar.scope(:fingerprint => fingerprint).error(e, data)
      else
        Rollbar.error(e, data)
      end
    end

  end
end
