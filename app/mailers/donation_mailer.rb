class DonationMailer < ActionMailer::Base
  default :from => "do-not-reply@smartservice.qld.gov.au"
  
  def donation_confirmation(donation)
    @donation = donation
    mail(:to => donation.customer.email, 
      :subject => "Smart Service Queensland - Tax Receipt: #{donation.id}")
  end
  
  def snail_mail_confirmation(donation)
    @donation = donation
    mail(:to => "campaigns@smartservice.qld.gov.au", 
      :subject => "Smart Service Queensland - Receipt: #{donation.id}")    
  end
  
end
