===============
PowerDNS Models
===============

:Author: Garry Dolley
:Date: 07-05-2011

This repository contains a couple of ActiveRecord models that can be used to
manipulate a PowerDNS database.

The models included are:

* DnsDomain

  The ``domains`` table

* DnsRecord

  The ``records`` table

These models are compatible with the stock PowerDNS tables listed above.  You
do not need to make any changes or run any migrations.

There is, however, one migration included in ``db/migrate`` for those have not
yet installed a PowerDNS database.  It will create the ``domains`` and
``records`` tables.

Requirements
------------

* ActiveRecord
* NetAddr
* FactoryGirl (for running specs)

Installation
------------

::

  cd vendors/plugins/
  git clone git@github.com:up_the_irons/powerdns-models.git

In your ``config/database.yml``, define a ``powerdns_development`` stanza, for
example::

  powerdns_development:
    adapter: mysql
    database: powerdns_development
    username: powerdns
    password: mypass

Do the same for ``powerdns_production``.

The models will try to establish a connection to the database in this
configuration, leaving the database of your main application alone.

If you don't already have a PowerDNS database set up, run the single migration
under ``db/migrate``.

TODO
----

* Make a gem version
* Migration only catches MySQL specific errors; make more generic
* Create a rake task to run migrations for installation

Author
------

Garry C. Dolley

gdolley [at] NOSPAM- arpnetworks.com

AIM: garry97531

IRC: I am up_the_irons on Freenode.

Formatting
----------

This README is formatted in reStructredText [RST]_.  It has the best
correlation between what a document looks like as plain text vs. its
formatted output (HTML, LaTeX, etc...).  What I like best is, markup
doesn't look like markup, even though it is.

.. [RST] http://docutils.sourceforge.net/rst.html

Copyright
---------

Copyright (c) 2011 ARP Networks, Inc.

Released under the MIT license.
