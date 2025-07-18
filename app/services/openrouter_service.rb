require 'net/http'
require 'json'

class OpenrouterService
  BASE_URL = 'https://openrouter.ai/api/v1'

  def self.fetch_models
    begin
      uri = URI("#{BASE_URL}/models")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 10
      http.open_timeout = 10

      request = Net::HTTP::Get.new(uri)
      request['Content-Type'] = 'application/json'

      response = http.request(request)

      if response.code == '200'
        data = JSON.parse(response.body)
        models = data['data']
        
        # Format all models for the dropdown
        formatted_models = models.map { |model|
          display_name = format_model_name(model)
          [display_name, model['id']]
        }.sort_by(&:first)

        # Return all models or fallback if empty
        if formatted_models.empty?
          default_models
        else
          formatted_models
        end
      else
        Rails.logger.error "OpenRouter API error: #{response.code} - #{response.message}"
        default_models
      end
    rescue StandardError => e
      Rails.logger.error "OpenRouter API connection error: #{e.message}"
      default_models
    end
  end

  private

  def self.format_model_name(model)
    name = model['name'] || model['id']
    
    # Add context information for better identification
    case model['id']
    when /^openai\//
      "#{name} (OpenAI)"
    when /^anthropic\//
      "#{name} (Anthropic)"
    when /^google\//
      "#{name} (Google)"
    when /^meta-llama\//
      "#{name} (Meta)"
    when /^mistralai\//
      "#{name} (Mistral AI)"
    when /^cohere\//
      "#{name} (Cohere)"
    else
      # Try to extract provider from ID
      provider = model['id'].split('/').first&.capitalize
      if provider && provider != model['id']
        "#{name} (#{provider})"
      else
        name
      end
    end
  end

  def self.default_models
    [
      ['GPT-4o (OpenAI) - Recommended', 'openai/gpt-4o'],
      ['GPT-4o Mini (OpenAI) - Fast & Affordable', 'openai/gpt-4o-mini'],
      ['Claude 3.5 Sonnet (Anthropic)', 'anthropic/claude-3.5-sonnet'],
      ['Claude 3 Haiku (Anthropic) - Fast', 'anthropic/claude-3-haiku'],
      ['Gemini Pro 1.5 (Google)', 'google/gemini-pro-1.5'],
      ['Llama 3.1 70B (Meta)', 'meta-llama/llama-3.1-70b-instruct'],
      ['Llama 3.1 8B (Meta) - Fast', 'meta-llama/llama-3.1-8b-instruct'],
      ['Mistral 7B (Mistral AI) - Fast', 'mistralai/mistral-7b-instruct']
    ]
  end
end 