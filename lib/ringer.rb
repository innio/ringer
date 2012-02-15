require 'ringer/version'
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
      }
    ]

    CONFIG.each do |block|
      # Dynamically inject methods as defined in the config.
      define_method(block[:method].to_sym) do |*args|
        method = block[:method]
        fields = block[:fields]
        namespace = block[:namespace]

        # Remove unknown properties that are going to get in the way
        data = args[0].delete_if {|key, value| !fields.include?(key)}

        # Insert a suffeciently unique transaction ID.
        data["TransactionId"] = transaction_id unless data.has_key?("TransactionId")

        # Make the call
        return request(method, {namespace => data})
      end
    end

    # Setup the connection and store the login info.
    # @param {String} username  Login name
    # @param {String} password Password
    # @param {Number} partner_id Partner ID number
    def initialize(username, password, partner_id)
      @username = username
      @password = password
      @partner_id = partner_id

      @client = Savon::Client.new("https://www.wyless.net:9443/PorthosAPI/PorthosWSF2.asmx?WSDL")
    end

    # Send a request to the SOAP endpoint.
    # @param [String] method The underscore_name of the remote method to call.
    #   Must respond to '#to_s'.
    # @param [Hash{String => String, Number,Boolean}] data The body of the request.
    # @return [String, Hash, nil] The response to the request.
    def request(method, data)
      response = @client.request(method.to_sym) do
        soap.header = header
        soap.body = data
      end
      return response["#{method}_response".to_sym]["#{method}_result".to_sym]
    end


    private

    # The header information needed to for the request.
    # @return [Hash{String => Hash{String => String}}] The connection details.
    def header
      {
        'wsdl:Credential' => {
          'wsdl:Login' => @username,
          'wsdl:Password' => @password,
          'wsdl:PartnerId' => @partner_id
        }
      }
    end

    # Unique transaction id.
    # @return [String] Short unique identifier for this transaction.
    def transaction_id
      rand(36**8).to_s(36)
    end
  end
end
