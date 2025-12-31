class Rack::Attack
  # Throttle all requests by IP (300 requests per 5 minutes)
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip
  end

  # Throttle login attempts by IP (5 attempts per 20 seconds)
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.ip
    end
  end

  # Throttle login attempts by email (5 attempts per minute)
  throttle("logins/email", limit: 5, period: 60.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.params.dig("user", "email")&.downcase&.strip
    end
  end

  # Block suspicious requests (SQL injection, etc.)
  blocklist("block/bad-requests") do |req|
    Rack::Attack::Fail2Ban.filter("bad-params-#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 1.hour) do
      CGI.unescape(req.query_string) =~ %r{/etc/passwd|union.*select|<script}i rescue false
    end
  end
end
