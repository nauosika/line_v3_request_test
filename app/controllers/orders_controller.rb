class OrdersController < ApplicationController
  before_action :header_nonce, only:[:create]
  before_action :body, only:[:create]
  before_action :header, only:[:create]

  def create
    response = JSON.parse(get_response.body)
    if response["returnMessage"] == "Success."
      redirect_to response["info"]["paymentUrl"]["web"]
    else
      puts response
    end
  end

  private
  def header_nonce
    @nonce = SecureRandom.uuid
  end

  def order_id
    "order#{SecureRandom.uuid}"
  end

  def packages_id
    "package#{SecureRandom.uuid}"
  end

  def amount
    params[:quantity].to_i * params[:price].to_i
  end

  def body
    @body = { amount: amount,
             currency: "TWD",
             orderId: order_id,
             packages: [ { id: packages_id,
                           amount: amount,
                           products: [ {
                           name: params[:name],
                           quantity: params[:quantity].to_i,
                           price: params[:price].to_i } ] } ],
             redirectUrls: { confirmUrl: "http://127.0.0.1:3000/confitmUrl",
                             cancelUrl: "http://127.0.0.1:3000/cancelUrl" } }
  end

  def get_signature
    secrect = ENV["lines_pay_ChannelSecret"]
    signature_uri = "/v3/payments/request"
    message = "#{secrect}#{signature_uri}#{@body.to_json}#{@nonce}"
    hash = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), secrect, message)
    @signature = Base64.strict_encode64(hash)
  end

  def header
    get_signature()
    @header = {"Content-Type": "application/json",
          "X-LINE-ChannelId": ENV["line_pay_ChannelID"],
          "X-LINE-Authorization-Nonce": @nonce,
          "X-LINE-Authorization": @signature }
  end

  def get_response
    uri = URI.parse("https://sandbox-api-pay.line.me/v3/payments/request")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri, @header)
    request.body = @body.to_json
    response = http.request(request)
  end
end
