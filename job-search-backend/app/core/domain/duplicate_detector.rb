module Domain
  # Pure-Ruby domain service (no dependencies). Flags a likely duplicate of a
  # candidate listing among existing ones using per-field Levenshtein similarity.
  #
  # Main match:     company + job_title (>= 85% similar) AND job_posted_date
  #                 within +/- 3 days. location/salary_range are tie-breakers.
  # Private match:  when either company is "Private Advertiser", fall back to
  #                 job_title + location + salary_range (no date window).
  # board_source is deliberately ignored (same job across boards is the target).
  #
  # Never blocks a save: callers use the result only as a soft warning.
  class DuplicateDetector
    THRESHOLD = 0.85
    DATE_WINDOW_DAYS = 3
    PRIVATE_ADVERTISER = "Private Advertiser".freeze

    # Returns the first existing listing that looks like a duplicate of
    # `candidate`, or nil if none do.
    def find_duplicate(candidate, existing)
      existing.find { |row| duplicate?(candidate, row) }
    end

    private

    def duplicate?(a, b)
      if private_advertiser?(a) || private_advertiser?(b)
        similar?(a.job_title, b.job_title) &&
          similar?(a.location, b.location) &&
          similar?(a.salary_range, b.salary_range)
      else
        within_date_window?(a.job_posted_date, b.job_posted_date) &&
          similar?(a.company, b.company) &&
          similar?(a.job_title, b.job_title)
      end
    end

    def private_advertiser?(listing)
      listing.company == PRIVATE_ADVERTISER
    end

    def within_date_window?(date1, date2)
      day1 = to_date(date1)
      day2 = to_date(date2)
      return false if day1.nil? || day2.nil?

      (day1 - day2).abs <= DATE_WINDOW_DAYS
    end

    # Coerce Date or ISO string to Date; nil on anything unparseable. Keeps the
    # detector a soft, never-crashing check even when fed a raw string date.
    def to_date(value)
      return value if value.is_a?(Date)
      return nil if value.nil? || value == ""

      Date.iso8601(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    def similar?(str1, str2)
      similarity(str1.to_s.downcase, str2.to_s.downcase) >= THRESHOLD
    end

    # 1.0 == identical, 0.0 == nothing in common.
    def similarity(str1, str2)
      return 1.0 if str1 == str2
      return 0.0 if str1.empty? || str2.empty?

      longest = [str1.length, str2.length].max
      (longest - levenshtein(str1, str2)).to_f / longest
    end

    def levenshtein(source, target)
      m = source.length
      n = target.length
      return n if m.zero?
      return m if n.zero?

      row = (0..n).to_a
      (1..m).each do |i|
        prev_diag = row[0]
        row[0] = i
        (1..n).each do |j|
          temp = row[j]
          cost = source[i - 1] == target[j - 1] ? 0 : 1
          row[j] = [row[j] + 1, row[j - 1] + 1, prev_diag + cost].min
          prev_diag = temp
        end
      end
      row[n]
    end
  end
end
