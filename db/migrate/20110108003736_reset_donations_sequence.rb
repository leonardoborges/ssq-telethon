class ResetDonationsSequence < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute("SELECT setval('donations_id_seq', 3000000, false);") unless ActiveRecord::Base.connection.adapter_name == 'SQLite'
  end

  def self.down
    ActiveRecord::Base.connection.execute("SELECT setval('donations_id_seq', 0, false);") unless ActiveRecord::Base.connection.adapter_name == 'SQLite'    
  end
end
