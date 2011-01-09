class DonationsController < ApplicationController
  ERROR_MESSAGES = {
    "0"	=> "Transaction approved",
    "1" => "Transaction could not be processed",
    "E" => "Transaction declined - contact issuing bank",
    "2" => "Transaction declined - contact issuing bank",
    "3"	=> "No reply from Processing Host",
    "4" => "Card has expired",
    "5"	=> "Insufficient credit"
  }

  def index
    response.headers['Cache-Control'] = 'public, max-age=300'
    @donation = Donation.new
    @donation.customer = Customer.new
  end

  def retry
    @return_code = flash[:return_code]
    return redirect_to root_url if @return_code.nil?

    @donation = Donation.find(flash[:transaction_reference])
    @error_msg = ERROR_MESSAGES[@return_code]
    render :action => "index"
  end

  def create
    donation = Donation.new
    donation.customer = Customer.new(params[:customer])
    donation.amount = params[:amount]
    donation.save!

    redirect_to GatewayUrlBuilder.new.to_url donation
  end

  def callback
    query_string = {}
    params.each {|k, v| query_string[k] = v unless %w[action controller source].include?(k)}
    given_hash = query_string.delete("vpc_SecureHash")
    return render :status => 403 if given_hash.nil?
    computed_hash = ParamsHasher.new(AppConstants.gateway_secret_hash).to_hash(query_string)
    return render :status => 403 unless computed_hash.upcase == given_hash.upcase
    
    return_code = params["vpc_TxnResponseCode"].to_s
    transaction_reference = params["vpc_MerchTxnRef"].to_s

    donation = Donation.find(transaction_reference)
    donation.return_code = return_code
    donation.save!

    deliver_messages(donation)

    flash[:transaction_reference] = transaction_reference
    flash[:return_code] = return_code

    return redirect_to "/donations/retry" unless return_code == "0"
    return redirect_to "/donations/complete"
  end

  def complete
  end
  
  def deliver_messages(donation)
    if (donation.customer.wants_receipt_by_email? && donation.return_code == "0")
      DonationMailer.delay.donation_confirmation(donation)
    end
    if (donation.customer.wants_receipt_by_snail_mail? && donation.return_code == "0")
      DonationMailer.delay.snail_mail_confirmation(donation)
    end        
  end
  private :deliver_messages
end
