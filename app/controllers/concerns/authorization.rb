module Authorization
  extend ActiveSupport::Concern

  private

  def authorize_graphql(record, query = nil)
    policy = Pundit.policy(current_user_from_token, record)
    query ||= action_name.to_sym

    raise GraphQL::ExecutionError, 'Not authorized' unless policy.public_send(query)

    policy
  end

  def pundit_user
    current_user_from_token
  end

  def current_user_from_token
    return nil unless authorization_header.present?

    token = extract_token_from_header
    return nil unless token

    decoded_token = JwtService.decode_and_verify(token)
    return nil unless decoded_token

    user_id = decoded_token['user_id']
    return nil unless user_id

    user = User.find_by(id: user_id)
    return nil unless user

    if user.tokens_valid_after.present? && decoded_token['iat'].present?
      return nil if Time.at(decoded_token['iat']) < user.tokens_valid_after
    end

    user
  rescue StandardError => e
    Rails.logger.warn "Authentication error: #{e.message}"
    nil
  end

  def authorization_header
    request.headers['Authorization']
  end

  def extract_token_from_header
    return nil unless authorization_header

    token_match = authorization_header.match(/^Bearer\s+(.+)$/i)
    token_match&.[](1)
  end
end
