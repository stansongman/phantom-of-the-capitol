
require "ostruct"
require "json"

require "rest-client"

require "cwc/office"
require "cwc/message"
require "cwc/topic_codes"

module Cwc
  class BadRequest < Exception
    attr_reader :original_exception, :errors

    def initialize(e)
      @original_exception = e
      @errors = Nokogiri::XML(e.response.body).xpath("//Error").map(&:content)
      if @errors.empty?
        @errors << e.response.body
      end
    end
  end

  class Client
    attr_accessor :options

    class << self
      def default_client_configuration=(x)
        @default_client_configuration = x
      end

      def default_client_configuration
        @default_client_configuration ||= {}
      end
    end

    def self.configure(options)
      self.default_client_configuration = options
    end

    # Required options keys
    #   api_key                         String
    #   delivery_agent			String, must match the api key owner
    #   delivery_agent_ack_email	String
    #   delivery_agent_contact_name	String
    #   delivery_agent_contact_email	String
    #   delivery_agent_contact_phone	String, format xxx-xxx-xxxx
    def initialize(options={})
      options = self.class.default_client_configuration.merge(options)
      self.options = {
        api_key: options.fetch(:api_key),
        host: options.fetch(:host),

        delivery_agent: {
          name: options.fetch(:delivery_agent),
          ack_email: options.fetch(:delivery_agent_ack_email),
          contact_name: options.fetch(:delivery_agent_contact_name),
          contact_email: options.fetch(:delivery_agent_contact_email),
          contact_phone: options.fetch(:delivery_agent_contact_phone)
        }
      }
    end

    # Params format
    # {
    #   campaign_id:		String
    #   recipient: {
    #     member_office:		String
    #     is_response_requested:	Boolean	?
    #     newsletter_opt_in:		Boolean	?
    #   },
    #   organization: {
    #     name:		String	?
    #     contact: {
    #       name:	String	?
    #       email:	String	?
    #       phone:	String	?
    #       about:	String	?
    #     }
    #   },
    #   constituent: {
    #     prefix:		String
    #     first_name:		String
    #     middle_name:		String	?
    #     last_name:		String
    #     suffix:		String	?
    #     title:		String	?
    #     organization:		String	?
    #     address:		Array[String]
    #     city:			String
    #     state_abbreviation:	String
    #     zip:			String
    #     phone:		String	?
    #     address_validation:	Boolean	?
    #     email:		String
    #     email_validation:	Boolean	?
    #  },
    #  message: {
    #    subject:			String
    #    library_of_congress_topics:	Array[String], drawn from Cwc::TopicCodes. Must give at least 1.
    #    bills:	{			Array[Hash]
    #      congress:			Integer	?
    #      type_abbreviation:		String
    #      number:			Integer
    #    },
    #    pro_or_con:			"pro" or "con"	?
    #    organization_statement:	String		?
    #    constituent_message:		String		?
    #    more_info:			String (URL)	?
    #  }
    #
    # Use message[:constituent_message] for personal message,
    # or  message[:organization_statement] for campaign message
    # At least one of these must be given
    def create_message(params)
      Cwc::Message.new.tap do |message|
        message.delivery[:agent] = options.fetch(:delivery_agent)
        message.delivery[:organization] = params.fetch(:organization, {})
        message.delivery[:campaign_id] = params.fetch(:campaign_id)

        message.recipient.merge!(params.fetch(:recipient))
        message.constituent.merge!(params.fetch(:constituent))
        message.message.merge!(params.fetch(:message))
      end
    end

    def deliver(message)
      RestClient.post action("/v2/message"), message.to_xml, { content_type: :xml }
      true
    rescue RestClient::BadRequest => e
      raise BadRequest.new(e)
    end

    def offices
      # this method was doing a request to a static JSON file on the CWC server. When their server temporarily went down, it brought down our form requests with it. I just put the parsed JSON here, but I think the JSON should be saved in config and then loaded in this method.
      if options[:host] =~ %r{^https://cwc.house.gov}
        ["HAK00","HAL01","HAL02","HAL03","HAL04","HAL05","HAL06",
         "HAL07","HAR01","HAR02","HAR03","HAR04","HAZ01","HAZ02",
         "HAZ03","HAZ04","HAZ05","HAZ06","HAZ07","HAZ08","HAZ09",
         "HCA01","HCA02","HCA03","HCA04","HCA05","HCA06","HCA07",
         "HCA08","HCA09","HCA10","HCA11","HCA12","HCA13","HCA14",
         "HCA15","HCA16","HCA17","HCA18","HCA19","HCA20","HCA21",
         "HCA22","HCA23","HCA24","HCA25","HCA26","HCA27","HCA28",
         "HCA29","HCA30","HCA31","HCA32","HCA33","HCA34","HCA35",
         "HCA36","HCA37","HCA38","HCA39","HCA40","HCA41","HCA42",
         "HCA43","HCA44","HCA45","HCA46","HCA47","HCA48","HCA49",
         "HCA50","HCA51","HCA52","HCA53","HCO01","HCO02","HCO03",
         "HCO04","HCO05","HCO06","HCO07","HCT01","HCT02","HCT03",
         "HCT04","HCT05","HDC00","HDE00","HFL01","HFL02","HFL03",
         "HFL04","HFL05","HFL06","HFL07","HFL08","HFL09","HFL10",
         "HFL11","HFL12","HFL13","HFL14","HFL15","HFL16","HFL17",
         "HFL18","HFL19","HFL20","HFL21","HFL22","HFL23","HFL24",
         "HFL25","HFL26","HFL27","HGA01","HGA02","HGA03","HGA04",
         "HGA05","HGA06","HGA07","HGA08","HGA09","HGA10","HGA11",
         "HGA12","HGA13","HGA14","HGU00","HHI01","HHI02","HIA01",
         "HIA02","HIA03","HIA04","HID01","HID02","HIL01","HIL02",
         "HIL03","HIL04","HIL05","HIL06","HIL07","HIL08","HIL09",
         "HIL10","HIL11","HIL12","HIL13","HIL14","HIL15","HIL16",
         "HIL17","HIL18","HIN01","HIN02","HIN03","HIN04","HIN05",
         "HIN06","HIN07","HIN08","HIN09","HKS01","HKS02","HKS03",
         "HKS04","HKY01","HKY02","HKY03","HKY04","HKY05","HKY06",
         "HLA01","HLA02","HLA03","HLA04","HLA05","HLA06","HMA01",
         "HMA02","HMA03","HMA04","HMA05","HMA06","HMA07","HMA08",
         "HMA09","HMD01","HMD02","HMD03","HMD04","HMD05","HMD06",
         "HMD07","HMD08","HME01","HME02","HMI01","HMI02","HMI03",
         "HMI04","HMI05","HMI06","HMI07","HMI08","HMI09","HMI10",
         "HMI11","HMI12","HMI13","HMI14","HMN01","HMN02","HMN03",
         "HMN04","HMN05","HMN06","HMN07","HMN08","HMO01","HMO02",
         "HMO03","HMO04","HMO05","HMO06","HMO07","HMO08","HMS01",
         "HMS02","HMS03","HMS04","HMT00","HNC01","HNC02","HNC03",
         "HNC04","HNC05","HNC06","HNC07","HNC08","HNC09","HNC10",
         "HNC11","HNC12","HNC13","HND00","HNE01","HNE02","HNE03",
         "HNH01","HNH02","HNJ01","HNJ02","HNJ03","HNJ04","HNJ05",
         "HNJ06","HNJ07","HNJ08","HNJ09","HNJ10","HNJ11","HNJ12",
         "HNM01","HNM02","HNM03","HNV01","HNV02","HNV03","HNV04",
         "HNY01","HNY02","HNY03","HNY04","HNY05","HNY06","HNY07",
         "HNY08","HNY09","HNY10","HNY11","HNY12","HNY13","HNY14",
         "HNY15","HNY16","HNY17","HNY18","HNY19","HNY20","HNY21",
         "HNY22","HNY23","HNY24","HNY25","HNY26","HNY27","HOH01",
         "HOH02","HOH03","HOH04","HOH05","HOH06","HOH07","HOH08",
         "HOH09","HOH10","HOH11","HOH12","HOH13","HOH14","HOH15",
         "HOH16","HOK01","HOK02","HOK03","HOK04","HOK05","HOR01",
         "HOR02","HOR03","HOR04","HOR05","HPA01","HPA02","HPA03",
         "HPA04","HPA05","HPA06","HPA07","HPA08","HPA09","HPA10",
         "HPA11","HPA12","HPA13","HPA14","HPA15","HPA16","HPA17",
         "HPA18","HPR00","HRI01","HRI02","HSC01","HSC02","HSC03",
         "HSC04","HSC05","HSC06","HSC07","HSD00","HTN01","HTN02",
         "HTN03","HTN04","HTN05","HTN06","HTN07","HTN08","HTN09",
         "HTX01","HTX02","HTX03","HTX04","HTX05","HTX06","HTX07",
         "HTX08","HTX09","HTX10","HTX11","HTX12","HTX13","HTX14",
         "HTX15","HTX16","HTX17","HTX18","HTX19","HTX20","HTX21",
         "HTX22","HTX23","HTX24","HTX25","HTX26","HTX27","HTX28",
         "HTX29","HTX30","HTX31","HTX32","HTX33","HTX34","HTX35",
         "HTX36","HUT01","HUT02","HUT03","HUT04","HVA01","HVA02",
         "HVA03","HVA04","HVA05","HVA06","HVA07","HVA08","HVA09",
         "HVA10","HVA11","HVI00","HVT00","HWA01","HWA02","HWA03",
         "HWA04","HWA05","HWA06","HWA07","HWA08","HWA09","HWA10",
         "HWI01","HWI02","HWI03","HWI04","HWI05","HWI06","HWI07",
         "HWI08","HWV01","HWV02","HWV03","HWY00","MP00"].map{ |code| Office.new(code) }
      else
        response = RestClient.get action("/offices")
        JSON.parse(response.body).map{ |code| Office.new(code) }
      end
    end

    def office_supported?(office_code)
      offices.find{ |office| office.code == office_code }.present?
    end

    protected

    def action(action)
      host = options[:host].sub(/\/+$/, '')
      action = action.sub(/^\/+/, '')
      "#{host}/#{action}?apikey=#{options[:api_key]}"
    end
  end
end
