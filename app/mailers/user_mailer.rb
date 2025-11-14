# Mailer for user-related notifications
class UserMailer < ApplicationMailer
  # Send welcome email with generated password to new users
  # @param user [User] The newly created user
  # @param password [String] The generated password (only sent once, never stored)
  def welcome_email_with_password(user, password)
    @user = user
    @password = password

    # In non-production environments this is a mock to avoid accidentally
    # sending real emails during development or tests. We still return a
    # Mail::Message so callers (and tests) can assert on it, but the real
    # recipient is suppressed in dev (not in test to keep existing specs).
    if Rails.env.production?
      mail(to: user.email, subject: "Welcome! Your account has been created")
    else
      Rails.logger.info("[MockEmail] welcome_email_with_password to=#{user.email} password=#{password}")

      # In test environment we keep the real recipient (tests assert on it)
      # but still render an inline plain-text body to avoid missing template
      # issues. In development we suppress the real recipient.
      safe_recipient = Rails.env.test? ? user.email : "no-reply@example.com"

      mail(to: safe_recipient, subject: "Welcome! Your account has been created") do |format|
        format.text do
          render plain: <<~BODY
            Hello #{user.full_name || user.email},

            Your account has been created.

            Password: #{password}

            For security, this password will only be sent once and cannot be retrieved later. Please store it securely.

            (Original recipient #{user.email} suppressed in non-production environment.)
          BODY
        end
      end
    end
  end
end
