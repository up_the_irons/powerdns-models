Factory.define :dns_domain do |d|
  d.name '0.0.10.in-addr.arpa'
end

Factory.define :dns_record do |r|
  r.association :dns_domain
  r.name '2.0.0.10.in-addr.arpa'
  r.content 'example.com'
  r.after_build do |r|
    r.type = 'PTR'
  end
end

# If I use inheritance, r.type remains 'PTR' and not 'CNAME'
Factory.define :dns_record_with_cname_type, :class => DnsRecord do |r|
  r.association :dns_domain
  r.name '2.0.0.10.in-addr.arpa'
  r.content 'example.com'
  r.after_build do |r|
    r.type = 'CNAME'
  end
end

Factory.define :dns_record_with_ns_type, :class => DnsRecord do |r|
  r.association :dns_domain
  r.name '2.0.0.10.in-addr.arpa'
  r.content 'example.com'
  r.after_build do |r|
    r.type = 'NS'
  end
end
