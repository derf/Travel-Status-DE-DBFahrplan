package Travel::Status::DE::DBFahrplan;

use strict;
use warnings;
use 5.010;
use utf8;

use Carp qw(confess);
use DateTime;
use DateTime::Format::Strptime;
use LWP::UserAgent;
use POSIX qw(strftime);
use JSON;

use Travel::Status::DE::DBFahrplan::Result;

our $VERSION = '0.00';

sub new {
	my ( $obj, %conf ) = @_;

	if ( not $conf{api_key} ) {
		confess('An API key must be provided');
	}

	my $date = $conf{date} // strftime( '%Y-%m-%d', localtime(time) );
	my $time = $conf{time} // strftime( '%H:%M',    localtime(time) );

	my %lwp_options = %{ $conf{lwp_options} // { timeout => 10 } };

	my $ua = LWP::UserAgent->new(%lwp_options);
	$ua->env_proxy;

	my $ref = {
		api_key        => $conf{api_key},
		developer_mode => $conf{developer_mode},
		station        => $conf{station},
		ua             => $ua,
	};

	bless( $ref, $obj );

	my $url
	  = 'http://open-api.bahn.de/bin/rest.exe/departureBoard'
	  . "?authKey=$conf{api_key}&lang=de&id=$conf{station}"
	  . "&date=$date&time=$time&format=json";

	my $reply = $ua->get($url);

	if ( $reply->is_error ) {
		$ref->{errstr} = $reply->status_line;
		return $ref;
	}

	my $raw_json = $reply->decoded_content;

	if ( $ref->{developer_mode} ) {
		say $raw_json;
	}

	$ref->{json} = decode_json($raw_json);

	return $ref;
}

sub errstr {
	my ($self) = @_;

	return $self->{errstr};
}

sub results {
	my ($self) = @_;

	if ( defined $self->{results} ) {
		return @{ $self->{results} };
	}

	$self->{results} = [];

	for my $dep ( @{ $self->{json}{DepartureBoard}{Departure} } ) {
		push(
			@{ $self->{results} },
			Travel::Status::DE::DBFahrplan::Result->new(
				json => $dep,
				ua   => $self->{ua}
			)
		);
	}

	return @{ $self->{results} };
}

1;
