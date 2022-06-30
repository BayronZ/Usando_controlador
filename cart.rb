class Cart < ApplicationRecord
    
    def order_payment(Order)
        order = Order.find(params[:cart][:order_id])
        #price must be in cents
        price = order.total * 100
        response = EXPRESS_GATEWAY.setup_purchase(price,
            ip: request.remote_ip,
            return_url: process_paypal_payment_cart_url,
            cancel_return_url: root_url,
            allow_guest_checkout: true,
            currency: "USD"
        )

        payment_method = PaymentMethod.find_by(code: "PEC")
        Payment.create(
            order_id: order.id,
            payment_method_id: payment_method.id,
            state: "processing",
            total: order.total,
            token: response.token
        )
    end

    def response_state(response)
        if response.success?
            payment = Payment.find_by(token: response.token)
            order = payment.order
        
            #update object states
            payment.state = "completed"
            order.state = "completed"
        
            ActiveRecord::Base.transaction do
                order.save!
                payment.save!
            end
        end
    end


end