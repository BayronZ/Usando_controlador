class CartsController < ApplicationController
    before_action :authenticate_user!
    
    def update
        product = params[:cart][:product_id]
        quantity = params[:cart][:quantity]
        current_order.add_product(product, quantity)
        redirect_to root_url, notice: "Product added successfuly"
    end

    def show
        @order = current_order
    end

    def pay_with_paypal
        order_payment(Order)
        redirect_to EXPRESS_GATEWAY.redirect_url_for(response.token)
    end

    def process_paypal_payment
        details = EXPRESS_GATEWAY.details_for(params[:token])
        express_purchase_options =
        {
            ip: request.remote_ip,
            token: params[:token],
            payer_id: details.payer_id,
            currency: "USD"
        }

        price = details.params["order_total"].to_d * 100
        
        response = EXPRESS_GATEWAY.purchase(price, express_purchase_options)
        response_state(response)
    end
end
