require File.dirname(__FILE__) + '/../spec_helper'

context "DnsDomain class with fixtures loaded" do
  before do
    DnsDomain.delete_all
    DnsRecord.delete_all

    @domain = Factory.create(:dns_domain)
    @record_soa = Factory.build(:dns_record,
                                :dns_domain => @domain)
    @record_soa.name = @domain.name
    @record_soa.type = 'SOA'
    @record_soa.content = 'ns1.example.com. admin.example.com. 1 28800 7200 604800 3600'
    @record_soa.save
  end

  context "soa()" do
    specify "should return the SOA record for this domain" do
      @domain.soa.should == @record_soa
    end
  end

  context "serial()" do
    specify "should return the serial number in the SOA record for this domain" do
      @domain.serial.should == 1
    end
  end

  context "increment_serial!()" do
    specify "should increment the serial number in SOA record by 1" do
      serial_orig = @domain.serial
      @domain.increment_serial!
      @domain.serial.should == serial_orig + 1
    end
  end
end
