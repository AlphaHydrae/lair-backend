module RedisHelper
  def lock_for_update key, timeout: 60, message: nil
    lock_key = "lock:#{key}"

    begin
      unless $redis.set lock_key, true, nx: true, ex: timeout
        raise ConflictError.new("Lock #{key} is already taken", reason: message || 'Resources conflict, please try again later')
      end

      yield if block_given?
    ensure
      $redis.del lock_key if block_given?
    end
  end
end
