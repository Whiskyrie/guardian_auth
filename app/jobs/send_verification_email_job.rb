class SendVerificationEmailJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user && !user.email_verified?

    token = user.generate_email_verification_token!
    UserMailer.verification_email(user, token).deliver_now
  rescue StandardError => e
    Rails.logger.error "SendVerificationEmailJob failed for user_id=#{user_id}: #{e.message}"
    raise e
  end
end
