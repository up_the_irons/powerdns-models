class DnsDomain < ActiveRecord::Base
  establish_connection "powerdns_#{RAILS_ENV}"
  set_table_name "domains"
  set_inheritance_column "inheritance_type"

  has_many :dns_records, :foreign_key => 'domain_id'
  alias :records :dns_records
  
  def soa
    DnsRecord.find_by_domain_id_and_type(id, 'SOA')
  end

  def serial
    # Third element of the SOA record is the serial number
    soa.content.split(' ')[2].to_i
  end

  def increment_serial!
    record_soa = soa

    if record_soa
      parts = record_soa.content.split(' ')
      parts[2] = serial + 1
      record_soa.content = parts.join(' ')
      record_soa.save
    end
  end
end
