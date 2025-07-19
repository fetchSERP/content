require 'net/http'
require 'json'

# Service object to fetch and format AI model list from OpenRouter API.
# Returns a hash suitable for `grouped_options_for_select`
#   {
#     "OpenAI"     => [["GPT-4o", "openai/gpt-4o"], ["GPT-4o Mini", "openai/gpt-4o-mini"]],
#     "Anthropic"  => [["Claude 3 Haiku", "anthropic/claude-3-haiku"]]
#   }
class OpenrouterService
  BASE_URL = 'https://openrouter.ai/api/v1'.freeze
  READ_TIMEOUT = 10
  OPEN_TIMEOUT = 10

  class << self
    # Public: Fetch list of models grouped by provider family.
    # On error or timeout falls back to default list.
    def fetch_models
      response = http_get('/api/v1/models')
      if response&.code == '200'
        data = JSON.parse(response.body)
        models = data['data'] || []
        format_models(models)
      else
        Rails.logger.error("OpenRouter fetch_models error: #{response&.code}")
      end
    rescue StandardError => e
      Rails.logger.error("OpenRouter fetch_models exception: #{e.message}")
    end

    private

    def http_get(path)
      uri = URI.join(BASE_URL, path)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = READ_TIMEOUT
      http.open_timeout = OPEN_TIMEOUT
      request = Net::HTTP::Get.new(uri)
      request['Content-Type'] = 'application/json'
      http.request(request)
    end

    # Build grouped hash { "Provider" => [[display, value], ...] }
    def format_models(api_models)
      grouped = Hash.new { |h, k| h[k] = [] }
      api_models.each do |m|
        id = m['id']
        provider_key, model_name = id.split('/', 2)
        provider = provider_key.to_s.capitalize.presence || 'Other'
        display = m['name'].presence || model_name || id
        grouped[provider] << [display, id]
      end
      # sort providers and models alphabetically
      grouped.transform_values { |arr| arr.sort_by(&:first) }.sort.to_h
    end

  end
end 