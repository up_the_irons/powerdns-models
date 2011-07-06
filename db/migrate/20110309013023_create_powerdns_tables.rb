# In production, we already have a PowerDNS database set up, so we
# do not want this migration to run.  Therefore, we test for RAILS_ENV
# below.

class CreatePowerdnsTables < ActiveRecord::Migration
  def self.up
    if ENV['RAILS_ENV'] != 'production'
      # Isn't there an easier way of getting this conifg?
      orig_connection_config = ActiveRecord::Base.connection.instance_eval do
        @config
      end

      ['development', 'test'].each do |env|
        begin
          ActiveRecord::Base.establish_connection "powerdns_#{env}"

          begin
            create_table :domains do |t|
              t.string  :name, :null => false
              t.string  :master
              t.integer :last_check
              t.string  :type, :null => false, :default => 'NATIVE'
              t.integer :notified_serial
              t.string  :account
            end

            add_index :domains, :name
          rescue StandardError => e
            if e.message =~ /Mysql::Error: Table '.*' already exists:/
              puts "Table :domains already exists, skipping..."
            else
              raise
            end
          end
  
          begin
            create_table :records do |t|
              t.integer :domain_id
              t.string  :name
              t.string  :type, :limit => 6
              t.string  :content
              t.integer :ttl
              t.integer :prio
              t.integer :change_date
            end

            add_index :records, :domain_id
            add_index :records, :name
            add_index :records, [:name, :type]
          rescue StandardError => e
            if e.message =~ /Mysql::Error: Table '.*' already exists:/
              puts "Table :records already exists, skipping..."
            else
              raise
            end
          end
        rescue StandardError => e
          if e.message =~ /database is not configured/
            puts "Cannot connect to PowerDNS database, skipping"
          else
            raise
          end
        end
      end

      ActiveRecord::Base.establish_connection orig_connection_config
    end
  end

  def self.down
    if ENV['RAILS_ENV'] != 'production'
      orig_connection_config = ActiveRecord::Base.connection.instance_eval do
        @config
      end

      begin
        ['development', 'test'].each do |env|
          ActiveRecord::Base.establish_connection "powerdns_#{env}"
          drop_table :domains
          drop_table :records
        end
      rescue StandardError => e
        if e.message =~ /database is not configured/
          puts "Cannot connect to PowerDNS database, skipping"
        else
          raise
        end
      end

      ActiveRecord::Base.establish_connection orig_connection_config
    end
  end
end
