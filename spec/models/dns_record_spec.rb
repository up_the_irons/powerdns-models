require File.dirname(__FILE__) + '/../spec_helper'

context "DnsRecord class with fixtures loaded" do
  before do
    DnsDomain.delete_all
    DnsRecord.delete_all
  end

  specify "should count two DnsRecords" do
    Factory.create(:dns_record)
    Factory.create(:dns_record)
    DnsRecord.count.should == 2
  end

  specify "should update domain serial in SOA after record modification" do
    soa_content_orig  = 'ns1.example.com. admin.example.com. 1 28800 7200 604800 3600'
    soa_content_new   = 'ns1.example.com. admin.example.com. 2 28800 7200 604800 3600'
    soa_content_new_2 = 'ns1.example.com. admin.example.com. 3 28800 7200 604800 3600'

    domain = Factory.create(:dns_domain)
    record = Factory.create(:dns_record,
                            :dns_domain => domain)
    record_soa = Factory.build(:dns_record,
                               :dns_domain => domain,
                               :content => soa_content_orig)
    record_soa.type = 'SOA'
    record_soa.save

    record_soa.content.should == soa_content_orig
    record.content = 'foo.com.'
    record.save
    record_soa.reload.content.should == soa_content_new
    record.domain.soa.content.should == soa_content_new # double check

    # Now delete the record and make sure serial is updated
    record.destroy
    record_soa.reload.content.should == soa_content_new_2
  end

  specify "should validate record belongs to the correct domain" do
    record = Factory.build(:dns_record)
    record.valid?.should == true
    record.name = "1.2.3.4.in-addr.arpa"
    record.valid?.should == false
  end

  specify "should ensure trailing dot is present for PTR records" do
    record = Factory.create(:dns_record)
    record.type = 'PTR'
    record.content = 'example.com'
    record.save
    record.content.should == 'example.com.'
  end

  specify "should not add extraneous trailing dot for PTR records" do
    record = Factory.create(:dns_record)
    record.type = 'PTR'
    record.content = 'example.com.'
    record.save
    record.content.should == 'example.com.'

    record.content = 'example.com..'
    record.save
    record.content.should == 'example.com.'
  end

  specify "should not allow empty nibbles in IPv6 records" do
    record = Factory.build(:dns_record,
                           :name => '2.0.0.0.0..0.0.0.0.0.0.0.0.0.0.0.0.0.0.f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa')
                                            # ^^ whoops!
    record.type = 'PTR'
    record.valid?.should == false
  end

  specify "should ensure IPv6 PTR records are of full length" do
    record = Factory.build(:dns_record,
                           :name => '2.0.0.0.0.0.0.0.0.0.f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa')
    record.type = 'PTR'
    record.valid?.should == false
  end

  specify "should ensure IPv4 reverse DNS records have allowable type" do
    record = Factory.build(:dns_record,
                           :name => '1.0.0.10.in-addr.arpa')
    record.type = 'crap'
    record.valid?.should == false
    record.errors.on(:type).should == 'is invalid'
  end

  specify "should ensure IPv6 reverse DNS records have allowable type" do
    record = Factory.build(:dns_record,
                           :dns_domain => 
                             Factory.build(:dns_domain,
                                           :name => '8.f.2.f.7.0.6.2.ip6.arpa'),
                           :name => '2.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa')
    record.type = 'crap'
    record.valid?.should == false
    record.errors.on(:type).should == 'is invalid'
  end

  specify "should ensure CNAME has a unique LHS when creating a type of CNAME" do
    record = Factory.build(:dns_record,
                           :name => '1.0.0.10.in-addr.arpa')
    record.type = 'PTR'
    record.save

    record = Factory.build(:dns_record,
                           :name => '1.0.0.10.in-addr.arpa')
    record.type = 'CNAME'
    record.valid?.should == false
    record.errors.on(:type).should == 'of CNAME must have unique LHS (do you have a PTR or NS record with the same IP / Name?)'
  end
  
  specify "should ensure CNAME has a unique LHS when creating a type other than CNAME" do
    record = Factory.build(:dns_record,
                           :name => '1.0.0.10.in-addr.arpa')
    record.type = 'CNAME'
    record.save
    record.valid?.should == true

    record = Factory.build(:dns_record,
                           :name => '1.0.0.10.in-addr.arpa')
    record.type = 'PTR'
    record.valid?.should == false
    record.errors.on(:type).should == 'of CNAME must have unique LHS (do you have a PTR or NS record with the same IP / Name?)'
  end

  specify "should set default TTL to 3600" do
    record = Factory.build(:dns_record)
    record.ttl.should == nil
    record.save
    record.ttl.should == 3600
  end

  specify "should set default priority to 0" do
    record = Factory.build(:dns_record)
    record.prio.should == nil
    record.save
    record.prio.should == 0
  end

  context "domain_id()" do
    specify "should return domain ID of record" do
      record = Factory.create(:dns_record)
      domain = record.dns_domain
      record.instance_eval do
        domain_id.should == domain.id
      end
    end
  end

  context "ip()" do
    # Note: The original version of ip() checked for the record type.
    # We don't do this anymore, but I left the specs as is; maybe one
    # day we'll bring the record type check back.
    specify "should return the IPv4 IP associated with this PTR record" do
      record = Factory.build(:dns_record,
                             :name => '9.0.0.10.in-addr.arpa')
      record.type = 'PTR'
      record.ip.should == '10.0.0.9'
    end
    specify "should return the IPv6 IP associated with this PTR record" do
      record = Factory.build(:dns_record,
                             :dns_domain => 
                               Factory.build(:dns_domain,
                                             :name => '8.f.2.f.7.0.6.2.ip6.arpa'),
                             :name => '2.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa')
      record.type = 'PTR'
      record.ip.should == '2607:f2f8:beef::2'
    end
    specify "should return the IPv4 IP associated with this CNAME record" do
      record = Factory.build(:dns_record,
                             :name => '9.0.0.10.in-addr.arpa')
      record.type = 'CNAME'
      record.ip.should == '10.0.0.9'
    end
    specify "should return the IPv6 IP associated with this CNAME record" do
      record = Factory.build(:dns_record,
                             :dns_domain => 
                               Factory.build(:dns_domain,
                                             :name => '8.f.2.f.7.0.6.2.ip6.arpa'),
                             :name => '2.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa')
      record.type = 'CNAME'
      record.ip.should == '2607:f2f8:beef::2'
    end
    specify "should return nil if the record cannot be translated into an IP address" do
      record = Factory.build(:dns_record,
                             :name => 'f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa')
      record.type = 'NS'
      record.ip.should == nil
    end
    specify "should return nil if any nibble in an IPv6 address is empty" do
      record = Factory.build(:dns_record,
                             :name => '2.0.0.0.0..0.0.0.0.0.0.0.0.0.0.0.0.0.0.f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa')
                                              # ^^ whoops!
      record.type = 'PTR'
      record.ip.should == nil
    end
  end
end
