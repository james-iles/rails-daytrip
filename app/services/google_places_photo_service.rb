class GooglePlacesPhotoService
  require 'net/http'
  require 'json'
  require 'openssl'

  def initialize(api_key = ENV['GOOGLE_PLACES_API_KEY'])
    @api_key = api_key
    @base_url = 'https://maps.googleapis.com/maps/api'
  end

  # Main method to get photo URL for a place
  def get_place_photo(place_name, city_name)
    place_id = find_place_id(place_name, city_name)
    return nil unless place_id

    photo_reference = get_photo_reference(place_id)
    return nil unless photo_reference

    build_photo_url(photo_reference)
  rescue StandardError => e
    Rails.logger.error "Error fetching Google photo: #{e.message}"
    nil
  end

  private

  # Unified HTTPS request using system CA certs
  def https_get(uri)
    uri = URI(uri)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.ca_file = OpenSSL::X509::DEFAULT_CERT_FILE

    request = Net::HTTP::Get.new(uri)

    http.request(request)
  end

  # Find place ID using Find Place API
  def find_place_id(place_name, city_name)
    query = URI.encode_www_form_component("#{place_name}, #{city_name}")
    url = "#{@base_url}/place/findplacefromtext/json?input=#{query}&inputtype=textquery&fields=place_id&key=#{@api_key}"

    response = https_get(url)
    return nil unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    data.dig('candidates', 0, 'place_id')
  end

  # Get the photo reference from Place Details
  def get_photo_reference(place_id)
    url = "#{@base_url}/place/details/json?place_id=#{place_id}&fields=photos&key=#{@api_key}"

    response = https_get(url)
    return nil unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    data.dig('result', 'photos', 0, 'photo_reference')
  end

  # Build Google Places photo URL
  def build_photo_url(photo_reference, max_width = 800)
    "#{@base_url}/place/photo?maxwidth=#{max_width}&photo_reference=#{photo_reference}&key=#{@api_key}"
  end
end
