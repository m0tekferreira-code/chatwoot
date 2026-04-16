module InstagramConcern
  extend ActiveSupport::Concern

  def instagram_client
    ::OAuth2::Client.new(
      client_id,
      client_secret,
      {
        site: 'https://api.instagram.com',
        authorize_url: 'https://www.instagram.com/oauth/authorize', # Atualizado para www
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

  def exchange_code_for_token(code)
    # Passo 1 (CRITICAL): Trocar code por token via POST
    # Conforme reportado, o Instagram EXIGE POST e Content-Type de formulário
    endpoint = 'https://api.instagram.com/oauth/access_token'
    params = {
      client_id: client_id,
      client_secret: client_secret,
      grant_type: 'authorization_code',
      redirect_uri: "#{base_url}/#{provider_name}/callback",
      code: code
    }

    Rails.logger.info "[Instagram-Auth] Iniciando troca de code (Passo 1) via POST..."
    
    response = HTTParty.post(
      endpoint,
      body: params,
      headers: { 
        'Accept' => 'application/json',
        'Content-Type' => 'application/x-www-form-urlencoded' 
      }
    )

    unless response.success?
      Rails.logger.error "[Instagram-Auth] Passo 1 FALHOU. Code: #{response.code}, Response: #{response.body}"
      raise "Failed to exchange code: #{response.body}"
    end

    data = JSON.parse(response.body)
    Rails.logger.info "[Instagram-Auth] Passo 1 concluído com SUCESSO."
    data
  end

  def exchange_for_long_lived_token(short_lived_token)
    # Passo 2: Trocar curta por longa duração via GET (segundo manual)
    # Mas se o GET der "method type: get unsupported", tentaremos POST
    endpoint = "https://graph.instagram.com/access_token"
    params = {
      grant_type: 'ig_exchange_token',
      client_secret: client_secret,
      access_token: short_lived_token
    }

    Rails.logger.info "[Instagram-Auth] Iniciando Passo 2 (Long-lived) via GET..."
    make_api_request(endpoint, params, 'Failed to exchange token', :get)
  end

  def fetch_instagram_user_details(access_token)
    # Endpoint de detalhes (URL curta sem v25.0)
    endpoint = 'https://graph.instagram.com/me'
    params = {
      fields: 'id,username,user_id,name,profile_picture_url,account_type',
      access_token: access_token
    }

    Rails.logger.info "Buscando detalhes do usuário no Instagram (Passo 3): #{endpoint}"
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
      # Log detalhado para depuração
      Rails.logger.error "#{error_prefix}. Status: #{response.code}, Body: #{response.body}"
      raise "#{error_prefix}: #{response.body}"
    end

    begin
      JSON.parse(response.body)
    rescue JSON::ParserError => e
      ChatwootExceptionTracker.new(e).capture_exception
      Rails.logger.error "Invalid JSON response from Instagram: #{response.body}"
      raise e
    end
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end
end
