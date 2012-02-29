#require 'ringer/version'
require 'savon'

module Ringer
  # Interact with the Wyless SOAP API.
  #
  # This class gets methods automatically added based on the cofiguration
  # to wrap the requests to the API.  You can bypass these by calling {#request}
  # manually if you're feeling lucky.
  class Wyless

    # TODO: Move this to YAML somewhere
    CONFIG = [
      {:method => 'single_sim_inquiry',
       :namespace => 'inputType',
       :fields => ['id', 'PorthosInternalReference', 'SIMNo', 'MSISDN', 'IMEI']
      },
      {:method => 'ping',
       :namespace => 'inputType',
       :fields => ['id', 'PorthosInternalReference', 'SIMNo', 'MSISDN', 'IMEI', 'SIMNumber', 'IP']
      },
      {:method => 'single_suspend_sim',
       :namespace => 'inputType',
       :fields => ['id', 'PorthosInternalReference', 'SIMNo', 'MSISDN', 'IMEI', 'ReuseForChangeSIM']
      },
      {:method => 'single_restore_sim',
       :namespace => 'inputType',
       :fields => ['id', 'PorthosInternalReference', 'SIMNo', 'MSISDN', 'IMEI']
      },
    ]

    CONFIG.each do |block|
      # Dynamically inject methods as defined in the config.
      define_method(block[:method].to_sym) do |*args|
        method = block[:method]
        fields = block[:fields] || []
        namespace = block[:namespace] || nil

        # Remove unknown properties that are going to get in the way
        data = nil
        data = args[0].delete_if {|key, value| !fields.include?(key)} unless args.empty?

        # Insert a suffeciently unique transaction ID.
        data["TransactionId"] = transaction_id unless (data.nil? or data.has_key?("TransactionId"))

        request = nil
        if !namespace.nil?
          request = {namespace => data}
        end
        # Make the call
        return request(method, request)
      end
    end

    # Setup the connection and store the login info.
    # @param {String} username  Login name
    # @param {String} password Password
    # @param {Number} partner_id Partner ID number
    # @param {Boolean} auto_auth Authenticate automatically (true by default)
    def initialize(username, password, partner_id, auto_auth=true)
      @username = username
      @password = password
      @partner_id = partner_id
      @session = nil

      @client = Savon::Client.new("https://www.wyless.net:9443/PorthosAPI/PorthosWSF2.asmx?WSDL")

      if auto_auth && !authenticate
        raise 'Unable to authenticate'
      end
    end

    # Authenticate with the server and store the session key.
    # @return [Boolean] Sucess / Failure.
    def authenticate
      response = request('authenticate', nil)
      # A failure to authenticate returns a nil response.
      if response.nil? || response.empty?
        return false
      else
        @session = response
        return true
      end
    end

    # Send a request to the SOAP endpoint.
    # @param [String] method The underscore_name of the remote method to call.
    #   Must respond to '#to_s'.
    # @param [Hash{String => String, Number,Boolean}] data The body of the request.
    # @return [String, Hash, nil] The response to the request.
    def request(method, data)
      response = @client.request(method.to_sym) do
        soap.header = header
        soap.body = data unless data.nil?
      end
      return response["#{method}_response".to_sym]["#{method}_result".to_sym]
    end


    private

    # The header information needed to for the request.
    # Use the session key if one exists, otherwise use the username and password.
    # @return [Hash{String => Hash{String => String}}] The connection details.
    def header
      if @session.nil?
        {
          'wsdl:Credential' => {
            'wsdl:Login' => @username,
            'wsdl:Password' => @password,
            'wsdl:PartnerId' => @partner_id
          }
        }
      else
        {
          'wsdl:Credential' => {
            'wsdl:SessionKey' => @session,
            'wsdl:PartnerId' => @partner_id
          }
        }
      end
    end

    # Unique transaction id.
    # @return [String] Short unique identifier for this transaction.
    def transaction_id
      rand(36**8).to_s(36)
    end
  end
end
