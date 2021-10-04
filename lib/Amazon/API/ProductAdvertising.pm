package Amazon::API::ProductAdvertising;

use Moose;
use Moose::Util::TypeConstraints;
use LWP::UserAgent;
use HTTP::Request;
use Net::Amazon::Signature::V4;
use Time::Piece;
use JSON;

my %locale = (
  'Australia'            => {
    host   => 'com.au',
    region => 'us-west-2'
  },
  'Brazil'               => {
    host   => 'com.br',
    region => 'us-east-1',
  },
  'Canada'               => {
    host   => 'ca',
    region => 'us-east-1',
  },
  'Egypt'                => {
    host   => 'eg',
    region => 'eu-west-1',
  },
  'France'               => {
    host   => 'fr',
    region => 'eu-west-1',
  },
  'Germany'              => {
    host   => 'de',
    region => 'eu-west-1',
  },
  'India'                => {
    host   => 'in',
    region => 'eu-west-1',
  },
  'Italy'                => {
    host   => 'it',
    region => 'eu-west-1',
  },
  'Japan'                => {
    host   => 'co.jp',
    region => 'us-west-1',
  },
  'Mexico'               => {
    host   => 'com.mx',
    region => 'us-east-1',
  },
  'Netherlands'          => {
    host   => 'nl',
    region => 'eu-west-1',
  },
  'Poland'               => {
    host   => 'pl',
    region => 'eu-west-1',
  },
  'Singapore'            => {
    host   => 'sg',
    region => 'us-west-2',
  },
  'Saudi Arabia'         => {
    host   => 'sa',
    region => 'eu-west-1',
  },
  'Spain'                => {
    host   => 'es',
    region => 'eu-west-1',
  },
  'Sweden'               => {
    host   => 'se',
    region => 'eu-west-1',
  },
  'Turkey'               => {
    host   => 'com.tr',
    region => 'eu-west-1',
  },
  'United Arab Emirates' => {
    host   => 'ae',
    region => 'eu-west-1',
  },
  'United Kingdom'       => {
    host   => 'co.uk',
    region => 'eu-west-1',
  },
  'United States'        => {
    host   => 'com',
    region => 'us-east-1',
  },
);

enum 'AmazonLocale', [ keys %locale ];

has service => (
  is => 'ro',
  isa => 'Str',
  default => 'ProductAdvertisingAPI',
);

has [qw( partner_tag access_key secret_key )] => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has partner_type => (
  is => 'ro',
  isa => 'Str',
  default => 'Associates',
);

has locale => (
  is => 'ro',
  isa => 'AmazonLocale',
  default => 'United States',
);

has base_domain => (
  is => 'ro',
  isa => 'Str',
  default => 'webservices.amazon.',
);

has api_path => (
  is => 'ro',
  isa => 'Str',
  default => 'paapi5',
);

sub host {
  my $self = shift;

  return $self->base_domain . $locale{$self->locale}->{host};
}

sub base_url {
  my $self = shift;

  return 'https://' . $self->host;
}

sub marketplace {
  my $self = shift;

  return 'www.amazon.' . $locale{$self->locale}->{host};
}

has searchitems_path => (
  is => 'ro',
  isa => 'Str',
  default => 'searchitems',
);

has searchitems_url => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

sub _build_searchitems_url {
  my $self = shift;

  return join '/', $self->base_url, $self->api_path, $self->searchitems_path;
}

has getitems_path => (
  is => 'ro',
  isa => 'Str',
  default => 'searchitems',
);

has getitems_url => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

sub _build_getitems_url {
  my $self = shift;

  return join '/', $self->base_url, $self->api_path, $self->getitems_path;
}
has ua => (
  is => 'ro',
  isa => 'LWP::UserAgent',
  lazy_build => 1,
);

sub _build_ua {
  my $self = shift;

  return LWP::UserAgent->new;
}

has signer => (
  is => 'ro',
  isa => 'Net::Amazon::Signature::V4',
  lazy_build => 1,
);

sub _build_signer {
  my $self = shift;

  return Net::Amazon::Signature::V4->new({
    access_key_id => $self->access_key,
    secret        => $self->secret_key,
    endpoint      => $locale{$self->locale}{region},
    service       => $self->service,
  });
}

sub searchitems {
  my $self = shift;

  return $self->request('searchitems', @_);
}

sub getitems {
  my $self = shift;

  return $self->request('getitems', @_);
}

sub request {
  my $self = shift;
  my ($operation, $params) = @_;

  my $url_method = $operation . '_url';
  my $tgt_method = $operation . '_target';

  my $endpoint = $self->$url_method;

  my $req = HTTP::Request->new(POST => $endpoint);
  $req->header('X-Amz-Date' => $self->amz_date);
  $req->header('X-Amz-Target' => $self->$tgt_method);
  $req->header(Host => $self->host);
  $req->header(Content_type => 'application/json; charset=UTF-8');
  $req->header(Content_encoding => 'amz-1.0');

  $params //= {};

  $params->{Marketplace} = $self->marketplace;
  $params->{PartnerType} = $self->partner_type;
  $params->{PartnerTag}  = $self->partner_tag;

  # Hardcoded stuff for now...
  $params->{Keywords}  //= 'kindle';
  $params->{Resources} //= [
    "Images.Primary.Large", "ItemInfo.Title", "Offers.Listings.Price",
  ];

  my $content = $self->json->encode($params);
  $req->content($content);

  $req = $self->signer->sign($req);

  warn $req->as_string;

  my $resp = $self->ua->request($req);

  my $data = $self->json->decode($resp->content);

  use Data::Dumper;
  warn Dumper $data;

  return $data;
}

sub amz_date {
  my $self = shift;

  return gmtime->strftime('%Y%m%dT%H%M%SZ');
}

sub searchitems_target {
  my $self = shift;

  return $self->target . '.SearchItems';
}

sub getitems_target {
  my $self = shift;

  return $self->target . '.GetItems';
}

has target => (
  is => 'ro',
  isa => 'Str',
  default => 'com.amazon.paapi5.v1.ProductAdvertisingAPIv1',
);

has json => (
  is => 'ro',
  isa => 'JSON',
  lazy_build => 1,
);

sub _build_json {
  return JSON->new;
}

1;
