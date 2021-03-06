class DonationsController < ApplicationController
  before_filter :redirect_to_ssl, :only => :index
  before_filter :force_cache, :only => :index
  before_filter :force_no_cache, :only => :complete
  
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
    if ENV['DEACTIVATED'] == 'true'
      redirect_to ENV['DEACTIVATED_URL'] and return
    end
    @donation = Donation.new
    @donation.customer = Customer.new(:wants_receipt_by_email => true)
  end

  def e5f4a96ae0e556fc021037059c97a640
    @donation = Donation.new
    @donation.customer = Customer.new(:wants_receipt_by_email => true)
    render :index
  end

  def retry
    @return_code = params[:return_code]
    return redirect_to root_url if @return_code.nil?

    @donation = Donation.find(params[:transaction_reference])
    @error_msg = ERROR_MESSAGES[@return_code]
    render :action => "index"
  end

  def create
    donation = Donation.new(params[:donation])
    donation.customer = Customer.new(params[:customer])
    donation.customer.wants_receipt_by_email = (params[:receipt_by] == 'email')
    donation.customer.wants_receipt_by_snail_mail = (params[:receipt_by] == 'snail_mail')
    donation.save

    donation.errors.delete(:customer)
    @errors = donation.errors.merge(donation.customer.errors)
    
    if @errors.empty?
      redirect_to GatewayUrlBuilder.new.to_url donation
    else
      @errors = donation.errors.merge(donation.customer.errors)
      @donation = donation
      render :action => "index"
    end
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

    params[:transaction_reference] = transaction_reference
    params[:return_code] = return_code

    return redirect_to "/donations/retry" unless return_code == "0"
    return redirect_to donations_complete_path(transaction_reference)
  end

  def complete
    @transaction_reference = params[:transaction_reference]
    redirect_to root_url if @transaction_reference.nil?
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
