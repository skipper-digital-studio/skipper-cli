# frozen_string_literal: true

require 'uri'
require 'json'
require 'http'
require 'skipper_client/models/models'
require 'skipper_client/models/requests'

# cosumer
class Consumer
  attr_reader :cfg

  def initialize(cfg)
    @cfg = cfg
  end

  def content_type
    { 'Content-Type' => 'application/json' }
  end

  def x_api_key
    { "x-api-key": token }
  end

  def merge_headers(*headers)
    HTTP.headers(headers.reduce { |output, header| output.merge(header) })
  end

  def token_valid?
    valid_uri = URI("#{uri}/auth/validate/#{token}".strip)
    begin
      (Models::SkipperResponse.from_response HTTP.get(valid_uri), Models::ValidApiKeyResponse).success
      true
    rescue StandardError
      false
    end
  end

  def create_api_key
    new_token_api = URI "#{uri}/internal/management/api_key"
    req = HTTP::Post.new new_token_api.path, content_type
    req.body = { origin: '*', name: 'new_api_key', purpose: 'general' }
    SkipperResponse.from_response HTTP.request(req), Models::ApiKeyResponse
  end

  def products
    products_uri = URI "#{uri}/api/v1/products"
    Models::SkipperResponse.from_response HTTP.headers("x-api-key": token).get(products_uri), Models::Price, :list
  end

  def coupon(coupon)
    validation_uri = URI "#{uri}/api/v1/products/coupons/#{coupon}".strip
    Models::SkipperResponse.from_response HTTP.headers("x-api-key": token).get(validation_uri), Models::Coupon,
                                          :unit
  end

  def customer_by_company_and_project(company, project)
    customers_uri = URI "#{uri}/api/v1/customers?project_name=#{project}&company_name=#{company}".strip
    Models::SkipperResponse.from_response HTTP.headers("x-api-key": token).get(customers_uri), Models::Customer,
                                          :unit
  rescue Models::SkipperApiError
    nil
  end

  def valid_coupon?(input)
    (coupon input).success
  rescue Models::SkipperApiError
    false
  end

  def checkout(checkout_req)
    raise 'Error checkout_req is not a JsonRequest' unless checkout_req.is_a? Models::JsonRequest

    checkout_uri = URI "#{uri}/api/v1/checkout"

    res = merge_headers(x_api_key, content_type).post(checkout_uri, json: checkout_req.as_json)
    Models::SkipperResponse.from_response res, Models::Checkout, :unit
  end

  def product(id)
    products.data.find { |d| d.external_id == id }
  end

  def uri
    @cfg.uri
  end

  def token
    @cfg.token
  end

  private

  def body_to_json(body)
    JSON.parse! body
  end
end
