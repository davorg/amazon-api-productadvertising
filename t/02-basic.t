use strict;
use warnings;

use Test::More;

use Amazon::API::ProductAdvertising;

my $attr2env = {
  partner_tag => 'AMAZON_ASSTAG',
  access_key  => 'AMAZON_KEY',
  secret_key  => 'AMAZON_SECRET',
};

my %new_params = map { $_ => $ENV{$attr2env->{$_}} } keys %$attr2env;

ok my $api = Amazon::API::ProductAdvertising->new( \%new_params ),
   'Got an object';
isa_ok $api, 'Amazon::API::ProductAdvertising';

for (keys %$attr2env) {
  is $api->$_, $ENV{$attr2env->{$_}}, "$_ is correct";
}

is $api->partner_type, 'Associates',             'partner_type is correct';
is $api->locale,       'United States',          'locale is correct';
is $api->host,         'webservices.amazon.com', 'host is correct';
is $api->marketplace,  'www.amazon.com',         'marketplace is correct';
is $api->searchitems_url,
   'https://webservices.amazon.com/paapi5/searchitems',
   'search_item_url is correct';

$api->searchitems;;

done_testing;
