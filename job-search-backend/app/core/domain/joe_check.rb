module Domain
  # Pure-Ruby domain service for the "Joe check": decides a listing's joe_status
  # from JSearch's job_offer_expiration_datetime_utc (stored as
  # job_offer_expires_at). Used when search results are mapped (setting a new
  # listing's initial status) and by the refresh button after fresh JSearch
  # data arrives (rules revised 23 Oct). Nothing server-side re-runs it on
  # stored data alone; the browser shows a passed date as amber on app load.
  #
  # New listing (apply):
  #   expiry passed      -> joe_status 1 (expired), status "closed"
  #   expiry in future   -> joe_status 0 (good),    status "active"
  #   no expiry known    -> listing unchanged (no evidence either way)
  #
  # Refresh with a fresh expiry date (refresh):
  #   0 or 1             -> 0 if the date is ahead, 1 if it has passed
  #   2 (manually dead)  -> latched: stays 2 while the date has passed, back to
  #                         0 if the date is ahead again
  #
  # The manual mark-as-dead toggle (Tracking page) moves a row between
  # MANUALLY_DEAD and EXPIRED only: un-marking never proves a job is good again,
  # so 0 is never a manual value.
  module JoeCheck
    GOOD = 0
    EXPIRED = 1
    MANUALLY_DEAD = 2
    MANUAL_VALUES = [EXPIRED, MANUALLY_DEAD].freeze

    module_function

    # Pulls the manual toggle out of a Tracking change set. Returns nil when the
    # change doesn't touch joe_status; raises if it sets anything but 1 or 2.
    def manual_value(changed_fields)
      fields = changed_fields.to_h.transform_keys(&:to_sym)
      return nil unless fields.key?(:joe_status)

      value = Integer(fields[:joe_status], exception: false)
      return value if MANUAL_VALUES.include?(value)

      raise Errors::ValidationFailed,
            "joe_status can only be set to #{MANUAL_VALUES.join(' or ')} manually, got #{fields[:joe_status].inspect}"
    end

    # Returns 0 or 1 for a known expiry, nil when there is none (or it can't be read).
    def status_for(expires_at, now: Time.current)
      time = parse(expires_at)
      return nil if time.nil?

      time < now ? EXPIRED : GOOD
    end

    # The refresh button's rule for one listing given JSearch's latest expiry.
    # No fresh date leaves the listing exactly as it was.
    def refresh(listing, fresh_expires_at, now: Time.current)
      status = status_for(fresh_expires_at, now: now)
      return listing if status.nil?

      joe = listing.manually_marked_dead? && status == EXPIRED ? MANUALLY_DEAD : status
      listing.with(job_offer_expires_at: parse(fresh_expires_at), joe_status: joe,
                   status: joe == GOOD ? "active" : "closed")
    end

    def apply(listing, now: Time.current)
      return listing if listing.manually_marked_dead?

      status = status_for(listing.job_offer_expires_at, now: now)
      return listing if status.nil?

      listing.with(joe_status: status, status: status == EXPIRED ? "closed" : "active")
    end

    def parse(value)
      return value if value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone)
      return nil if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError
      nil
    end
  end
end
