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
        token_method: :post # Forçando POST aqui
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

  def exchange_code_for_token(code)
    # Primeiro passo: Trocar o code pelo token de curta duração
    # Este endpoint EXIGE POST segundo a documentação e seu reporte
    endpoint = 'https://api.instagram.com/oauth/access_token'
    params = {
      client_id: client_id,
      client_secret: client_secret,
      grant_type: 'authorization_code',
      redirect_uri: "#{base_url}/#{provider_name}/callback",
      code: code
    }

    # Usando POST explícito e enviando params no corpo (body)
    response = HTTParty.post(
      endpoint,
      body: params,
      headers: { 'Accept' => 'application/json' }
    )

    unless response.success?
      Rails.logger.error "Failed to exchange code for token. Status: #{response.code}, Body: #{response.body}"
      raise "Failed to exchange code: #{response.body}"
    end

    JSON.parse(response.body)
  end

  def exchange_for_long_lived_token(short_lived_token)
    # Segundo passo: Trocar curta duração por longa duração
    endpoint = 'https://graph.instagram.com/v25.0/access_token'
    params = {
      grant_type: 'ig_exchange_token',
      client_secret: client_secret,
      access_token: short_lived_token
    }

    # Para este endpoint em graph.instagram.com, a Meta costuma lidar com GET ou POST
    # Vou usar POST para garantir, já que o GET deu erro de método antes
    make_api_request(endpoint, params, 'Failed to exchange token', :post)
  end

  def fetch_instagram_user_details(access_token)
    endpoint = 'https://graph.instagram.com/v25.0/me'
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
