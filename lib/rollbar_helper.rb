class RollbarHelper
  VERSION = "0.0.1"

  class << self

    def error(obj, fingerprint: nil)
      e = nil

      if obj.is_a?(Exception)
        e = obj
      else
        e = StandardError.new(obj.to_s)
        e.set_backtrace(caller)
      end

      if fingerprint.present?
        Rollbar.scope(:fingerprint => fingerprint).error(e)
      else
        Rollbar.error(e)
      end
    end

  end
end
