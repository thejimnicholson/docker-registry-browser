class Repository
  include ActiveModel::Model

  attr_accessor :name, :tags

  def self.all
    response = client.get "/v2/_catalog"
    response.body["repositories"].map { |name| new(name: name) }
  end

  def self.find(name)
    response = client.get "/v2/#{name}/tags/list"
    new(
      name: response.body["name"],
      tags: response.body["tags"]
    )
  end

  def tag(tag)
    response = self.class.client.get "/v2/#{name}/manifests/#{tag}" do |request|
      request.headers["Accept"] = "application/vnd.docker.distribution.manifest.v2+json"
    end
    response.body
  end

  private

  def self.client
    @client ||= begin
      Faraday.new(url: Rails.configuration.x.registry_url) do |f|
        f.request  :url_encoded
        f.response :logger
        f.adapter  Faraday.default_adapter
        f.use FaradayMiddleware::ParseJson, content_type: /json/
      end
    end
  end
end
