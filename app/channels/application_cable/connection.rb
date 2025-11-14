module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # ActionCable connection used to authenticate websocket clients.
    # It verifies a JWT (from params or Authorization header) and
    # exposes the verified user as `current_user` on the connection.
    identified_by :current_user

    # Called when a client attempts to connect. Sets `current_user`
    # to the user resolved by `find_verified_user` or rejects the
    # connection if verification fails.
    def connect
      self.current_user = find_verified_user
    end

    private

    # Find and return the verified user for this connection.
    # Steps:
    # - obtain a JWT either from `params[:token]` or the Authorization header
    # - load secret key from Rails credentials or ENV
    # - decode the token and fetch the user by id
    # - reject the connection for any decode errors or missing user
    def find_verified_user
      token = request.params[:token] || extract_token_from_headers

      if token
        begin
          # prefer Rails credentials, fall back to ENV; reject if neither is set
          secret_key = Rails.application.credentials.devise_jwt_secret_key || ENV["DEVISE_JWT_SECRET_KEY"]
          unless secret_key.present?
            return reject_unauthorized_connection
          end

          decoded_token = JWT.decode(
            token,
            secret_key,
            true,
            { algorithm: "HS256" }
          ).first

          user_id = decoded_token["id"]
          User.find(user_id)
        rescue JWT::DecodeError, ActiveRecord::RecordNotFound
          reject_unauthorized_connection
        end
      else
        reject_unauthorized_connection
      end
    end

    # Extract a Bearer token from the Authorization header if present.
    def extract_token_from_headers
      auth_header = request.headers["HTTP_AUTHORIZATION"]
      auth_header&.split(" ")&.last
    end
  end
end
