class SecurityHeadersMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)

    # Add security headers
    headers.merge!(security_headers)

    [status, headers, response]
  end

  private

  def security_headers
    {
      # Prevent MIME type sniffing
      'X-Content-Type-Options' => 'nosniff',

      # Prevent clickjacking
      'X-Frame-Options' => 'DENY',

      # Enable XSS protection
      'X-XSS-Protection' => '1; mode=block',

      # Force HTTPS in production
      'Strict-Transport-Security' => 'max-age=31536000; includeSubDomains',

      # Control referrer information
      'Referrer-Policy' => 'strict-origin-when-cross-origin',

      # Prevent Adobe Flash and PDF files from loading
      'X-Permitted-Cross-Domain-Policies' => 'none',

      # Content Security Policy
      'Content-Security-Policy' => content_security_policy,

      # Feature Policy / Permissions Policy
      'Permissions-Policy' => permissions_policy
    }
  end

  def content_security_policy
    [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline'",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: https:",
      "font-src 'self'",
      "connect-src 'self'",
      "frame-src 'none'",
      "object-src 'none'",
      "base-uri 'self'",
      "form-action 'self'"
    ].join('; ')
  end

  def permissions_policy
    [
      'camera=()',
      'microphone=()',
      'geolocation=()',
      'payment=()',
      'usb=()',
      'magnetometer=()',
      'accelerometer=()',
      'gyroscope=()'
    ].join(', ')
  end
end
