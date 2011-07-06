class DnsRecord < ActiveRecord::Base
  class EmptyNibbleError < StandardError
  end

  establish_connection "powerdns_#{RAILS_ENV}"
  set_table_name "records"
  set_inheritance_column "inheritance_type"

  belongs_to :dns_domain, :foreign_key => 'domain_id'
  alias :domain :dns_domain

  validates_presence_of :content
  validates_format_of   :content,
    :with => /^[0-9a-zA-Z\.\-]*$/,
    :message => 'can only contain numbers, letters, dashes and \'.\'',
    :if => Proc.new { |dns_record|
      if dns_record.type =~ /(PTR|NS|CNAME)/
        true
      end
  }

  validates_format_of   :name,
    :with => /^([0-9a-fA-F]\.){1,32}ip6\.arpa$/,
    :message => 'has bad format',
    :if => Proc.new { |dns_record|
      if dns_record.name =~ /\.ip6\.arpa$/
        true
      end
  }
  validates_format_of   :name,
    :with => /^([0-9a-fA-F]\.){32}ip6\.arpa$/,
    :message => 'has bad format (did you include all trailing zeros?)',
    :if => Proc.new { |dns_record|
      if dns_record.type == 'PTR' && dns_record.name =~ /\.ip6\.arpa$/
        true
      end
  }
  validates_format_of   :name,
    :with => /^([0-9]+\.){4}in-addr\.arpa$/,
    :message => 'has bad format',
    :if => Proc.new { |dns_record|
      if dns_record.type == 'PTR' && dns_record.name =~ /\.in-addr\.arpa$/
        true
      end
  }
  validates_format_of   :type,
    :with => /(SOA|PTR|NS|CNAME)/,
    :message => 'is invalid',
    :if => Proc.new { |dns_record|
      if dns_record.name =~ /\.arpa$/
        true
      end
  }

  def validate
    # Make sure record belongs to the correct domain
    if domain.nil? || name !~ /#{domain.name}$/
      errors.add(:name, "does not belong to the correct domain")
    end

    # CNAME must have unique LHS
    begin
      if type == 'CNAME'
        r = DnsRecord.find(:all, :conditions => ["name = ? and type != 'CNAME'", name])
        if r && r.size > 0
          raise
        end
      else
        r = DnsRecord.find(:all, :conditions => ["name = ? and type = 'CNAME'", name])
        if r && r.size > 0
          raise
        end
      end
    rescue
      errors.add(:type, "of CNAME must have unique LHS (do you have a PTR or NS record with the same IP / Name?)")
    end
  end

  def before_save
    if type == 'PTR'
      if content
        self.content = content.sub(/\.+$/, '') + '.'
      end
    end

    if !ttl
      self.ttl = 3600
    end

    if !prio
      self.prio = 0
    end
  end

  def after_save
    if type != 'SOA'
      # Update serial number in domain's SOA
      domain.increment_serial!
    end
  end

  def after_destroy
    if type != 'SOA'
      # Update serial number in domain's SOA
      domain.increment_serial!
    end
  end

  # Return the IP associated with this record if it can be deduced
  # from the record name
  def ip
    ip = nil

    unless valid?
      return nil
    end

    begin
      case name
      when /\.in-addr\.arpa$/
        name_without_suffix = name.sub(/\.in-addr\.arpa$/, '')
        quads = name_without_suffix.split('.')
        if quads.size == 4
          quads.reverse!
          ip = quads.join('.')
        end
      when /\.ip6\.arpa$/
        name_without_suffix = name.sub(/\.ip6\.arpa$/, '')
        nibbles = name_without_suffix.split('.')
        nibbles.each do |nibble|
          if nibble.empty?
            raise DnsRecord::EmptyNibbleError
          end
        end
        if nibbles.size == 32
          n = nibbles.reverse!
          ip = \
            n[0..3].join('')   + ":" +
            n[4..7].join('')   + ":" +
            n[8..11].join('')  + ":" +
            n[12..15].join('') + ":" +
            n[16..19].join('') + ":" +
            n[20..23].join('') + ":" +
            n[24..27].join('') + ":" +
            n[28..31].join('')
          
          ip = NetAddr::CIDR.create(ip).ip(:Short => true)
        end
      end
    rescue DnsRecord::EmptyNibbleError
      ip = nil
    end

    ip
  end

  def r_type
    get_attribute(:type)
  end

  def r_type=(type)
    set_attribute(:type, type)
  end

  protected

  def domain_id
    dns_domain.id
  end
end
