module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      session = Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
      unless session
        encrypted_email = cookies.permanent[:cross_app_email_enc]
        if encrypted_email
          shared_secret = Rails.application.credentials.cross_app_cookie_secret
          key = ActiveSupport::KeyGenerator.new(shared_secret).generate_key("cross_app_cookie_salt", 32)
          encryptor = ActiveSupport::MessageEncryptor.new(key, cipher: "aes-256-gcm")
          email = encryptor.decrypt_and_verify(encrypted_email)
          user = User.find_by(email_address: email)
          session = user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip)
          cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
        end
      end
      session
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || app_root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }

        shared_secret = Rails.application.credentials.cross_app_cookie_secret

        # Generate a 32-byte key for AES-256-GCM
        key = ActiveSupport::KeyGenerator.new(shared_secret).generate_key("cross_app_cookie_salt", 32)
        encryptor = ActiveSupport::MessageEncryptor.new(key, cipher: "aes-256-gcm")

        encrypted_email = encryptor.encrypt_and_sign(user.email_address)

        cookies.permanent[:cross_app_email_enc] = {
          value:  encrypted_email,
          # domain: ".fetchserp.local",          # available to keywords.fetchserp.com
          domain: ".fetchserp.com",          # available to keywords.fetchserp.com
          secure: Rails.env.production?,     # only over HTTPS in production
          httponly: true,                    # JS can’t read it
          same_site: :lax
        }
      rescue => e
        Rails.logger.error("Unable to set cross-app email cookie: #{e.message}")
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
      cookies.delete(
        :cross_app_email_enc,
        domain: ".fetchserp.com",
        secure: Rails.env.production?,
        httponly: true,
        same_site: :lax
      )
    end
end
