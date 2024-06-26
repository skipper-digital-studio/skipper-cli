# frozen_string_literal: true

require 'json'

module Models
  # Skipper api Exception
  class SkipperApiError < StandardError; end

  class MissingFromJSON < StandardError; end

  # json model
  class JsonModel
    def self.from_json(_json_dict)
      raise 'not implemented'
    end
  end

  # Basic skipper response
  class SkipperResponse
    attr_reader :success, :message, :data

    def initialize(json_dict, data)
      @success = json_dict['success']
      @message = json_dict['message']
      @data = data
    end

    def self.from_response(response, data_class, type)
      raise SkipperApiError, response.to_s unless response.status.success?
      raise MissingFromJSON, 'missing from_json method' unless data_class < JsonModel

      _parse_from_response parse_json(response.body), data_class, type
    end

    def self.parse_json(body)
      JSON.parse! body
    end

    def self._parse_from_response(json_dict, data_class, type)
      case type
      when :unit
        _from_unit_response json_dict, data_class
      when :list
        _from_list_response json_dict, data_class
      else
        raise SkipperApiError, 'invalid type passed'
      end
    end

    def self._from_unit_response(json_dict, data_class)
      json_data = json_dict['data']
      raise SkipperApiError, 'data was expected to not be a list' if json_data.is_a? Array

      new json_dict, data_class.from_json(json_dict['data'])
    end

    def self._from_list_response(json_dict, data_class)
      json_data = json_dict['data']
      raise SkipperApiError, 'data was expected to be a list' unless json_data.is_a? Array

      new(json_dict, json_data.map { |item| data_class.from_json(item) })
    end
  end

  # api create api key response
  class ApiKeyResponse < JsonModel
    attr_accessor :key

    def initialize(key)
      @key = key
      super()
    end

    def self.from_json(json_dict)
      new json_dict['key']
    end
  end

  # api key models
  class ValidApiKeyResponse < JsonModel
    attr_reader :value, :name, :origin, :purpose

    def initialize(value, name, origin, purpose)
      @value = value
      @name = name
      @origin = origin
      @purpose = purpose
      super()
    end

    def self.from_json(json_dict)
      new json_dict['value'], json_dict['name'], json_dict['origin'], json_dict['purpose']
    end
  end

  # ExternalID string        `json:"external_id"`
  # Product    Product       `json:"product"`
  # Currency   string        `json:"currency"`
  # Amount     int64         `json:"amount"`
  # StripeData *stripe.Price `json:"stripe_data"`
  class Price < JsonModel
    attr_reader :external_id, :product, :currency, :amount, :stripe_data, :billing_schema

    def initialize(external_id, product, currency, amount, stripe_data)
      @external_id = external_id
      @product = product
      @currency = currency
      @amount = amount
      @stripe_data = stripe_data
      @billing_schema = amount > 300_000 ? 'monthly' : 'weekly'
      super()
    end

    def self.from_json(json_dict)
      new json_dict['external_id'], json_dict['product'], json_dict['currency'], json_dict['amount'],
          json_dict['stripe_data']
    end

    def to_dollar
      (@amount / 100).to_s
    end
  end

  # checkout session created res
  class Checkout < JsonModel
    attr_reader :payment_url

    def initialize(payment_url)
      @payment_url = payment_url
      super()
    end

    def self.from_json(json_dict)
      new json_dict['payment_url']
    end
  end

  # ExternalID       string  `json:"id"`
  # PercentOff       float64 `json:"percent_off"`
  # Duration         string  `json:"duration"`
  # DurationInMonths int64   `json:"duration_in_months"`
  class Coupon < JsonModel
    attr_reader :id, :name, :percent_off, :duration, :duration_in_months

    def initialize(id, name, _percent_off, duration, duration_in_months)
      @id = id
      @name = name
      @duration = duration
      @duration_in_months = duration_in_months
      @percent_off = percent_off
      super()
    end

    def self.from_json(json_dict)
      new json_dict['id'], json_dict['name'], json_dict['percent_off'], json_dict['duration'],
          json_dict['duration_in_months']
    end
  end

  # ID              int        `db:"id"`
  # CompanyName     string     `db:"company_name" json:"company_name"`
  # ProjectName     string     `db:"project_name" json:"project_name"`
  class Customer < JsonModel
    attr_reader :id, :company_name, :project_name

    def initialize(id, company_name, project_name)
      @id = id
      @company_name = company_name
      @project_name = project_name
    end

    def self.from_json(json_dict)
      new json_dict['id'], json_dict['company_name'], json_dict['project_name']
    end
  end
end
