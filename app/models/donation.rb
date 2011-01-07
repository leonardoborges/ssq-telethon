class Donation < ActiveRecord::Base
  belongs_to :customer
  validates_presence_of :amount, :transaction_reference, :order_info

  after_initialize do
    self.generate_identifiers! if new_record?
  end

  def generate_identifiers!
    @@uuid_generator ||= UUID.new
    self.order_info = self.transaction_reference = @@uuid_generator.generate(:compact).to_s
  end
end
