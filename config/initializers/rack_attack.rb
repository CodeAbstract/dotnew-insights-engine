class Rack::Attack
  ### Configure Cache ###
  Rack::Attack.cache.store = Rails.cache

  ### Rate Limiting ###
  
  # Global rate limit
  throttle('req/ip', limit: ENV.fetch('GLOBAL_RATE_LIMIT', 300).to_i, period: ENV.fetch('GLOBAL_RATE_LIMIT_PERIOD', 300).to_i) do |req|
    req.ip
  end

  # Rate limit for analytics tracking
  throttle('analytics/track/ip', limit: ENV.fetch('TRACK_RATE_LIMIT', 60).to_i, period: ENV.fetch('TRACK_RATE_LIMIT_PERIOD', 60).to_i) do |req|
    if req.path == '/api/v1/analytics/track' && req.post?
      req.ip
    end
  end

  # API rate limit
  throttle('api/ip', limit: ENV.fetch('API_RATE_LIMIT_MAX_REQUESTS', 100).to_i, period: ENV.fetch('API_RATE_LIMIT_WINDOW', 300).to_i) do |req|
    if req.path.start_with?('/api/')
      req.ip
    end
  end

  # Block suspicious requests
  blocklist('block suspicious requests') do |req|
    Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 1.hour) do
      # Return true for potentially malicious requests
      CGI.unescape(req.query_string) =~ %r{/etc/passwd} ||
      req.path.include?('/etc/passwd') ||
      req.path.include?('wp-admin') ||
      req.path.include?('wp-login')
    end
  end

  ### Custom Response ###
  self.throttled_response = lambda do |env|
    now = Time.now
    match_data = env['rack.attack.match_data']

    headers = {
      'Content-Type' => 'application/json',
      'X-RateLimit-Limit' => match_data[:limit].to_s,
      'X-RateLimit-Remaining' => '0',
      'X-RateLimit-Reset' => (now + (match_data[:period] - now.to_i % match_data[:period])).to_s
    }

    [429, headers, [{ error: "Rate limit exceeded. Please try again in #{match_data[:period]} seconds" }.to_json]]
  end
end 