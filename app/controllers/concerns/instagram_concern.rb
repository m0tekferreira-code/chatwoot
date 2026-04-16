module InstagramConcern
  extend ActiveSupport::Concern

  def instagram_client
    ::OAuth2::Client.new(
      client_id,
      client_secret,
      {
        site: 'https://api.instagram.com',
        authorize_url: 'https://api.instagram.com/oauth/authorize',
        token_url: 'https://api.instagram.com/oauth/access_token',
        auth_scheme: :request_body,
        token_method: :post
      }
    )
  end

  private

  def client_id
    GlobalConfigService.load('INSTAGRAM_APP_ID', nil)
  end

  def client_secret
    GlobalConfigService.load('INSTAGRAM_APP_SECRET', nil)
  end

  def exchange_for_long_lived_token(short_lived_token)
    # Mudando para o domínio da Meta (Facebook) que é mais estável para troca de tokens
    endpoint = 'https://graph.facebook.com/v21.0/oauth/access_token'
    params = {
      grant_type: 'fb_exchange_token', # Usando fb_exchange_token que é o padrão da Meta
      client_secret: client_secret,
      fb_exchange_token: short_lived_token,
      client_id: client_id
    }

    make_api_request(endpoint, params, 'Failed to exchange token', :get)
  end

  def fetch_instagram_user_details(access_token)
    # Mantendo instagram.com para o "me" pois ainda é o padrão para Basic Display
    endpoint = 'https://graph.instagram.com/v21.0/me'
    params = {
      fields: 'id,username,user_id,name,profile_picture_url,account_type',
      access_token: access_token
    }

    make_api_request(endpoint, params, 'Failed to fetch Instagram user details', :get)
  end

  def make_api_request(endpoint, params, error_prefix, method = :get)
    if method == :post
      response = HTTParty.post(
        endpoint,
        body: params,
        headers: { 'Accept' => 'application/json' }
      )
    else
      response = HTTParty.get(
        endpoint,
        query: params,
        headers: { 'Accept' => 'application/json' }
      )
    end

    unless response.success?
      Rails.logger.error "#{error_prefix}. Status: #{response.code}, Body: #{response.body}"
      raise "#{error_prefix}: #{response.body}"
    end

    begin
      JSON.parse(response.body)
    rescue JSON::ParserError => e
      ChatwootExceptionTracker.new(e).capture_exception
      Rails.logger.error "Invalid JSON response: #{response.body}"
      raise e
    end
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end
end
