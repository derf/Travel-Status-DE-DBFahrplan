package Travel::Status::DE::DBFahrplan::Result;

use strict;
use warnings;
use 5.010;

use parent 'Class::Accessor';
use JSON;

our $VERSION = '0.00';

Travel::Status::DE::DBFahrplan::Result->mk_ro_accessors(
	qw(train line type date time destination platform ref));

sub new {
	my ( $obj, %data ) = @_;

	my $ref = {
		train       => $data{json}{name},
		line        => $data{json}{name},
		type        => $data{json}{type},
		date        => $data{json}{date},
		time        => $data{json}{time},
		destination => $data{json}{direction},
		station     => $data{json}{stop},
		station_id  => $data{json}{stopid},
		platform    => $data{json}{track},
		detail_url  => $data{json}{JourneyDetailRef}{ref},
		ua          => $data{ua},
	};

	return bless( $ref, $obj );
}

sub get_detail_json {
	my ($self) = @_;
	my $ua = $self->{ua};

	if ( exists $self->{sched_route} ) {
		return;
	}

	my $reply = $ua->get( $self->{detail_url} );
	if ( $reply->is_error ) {
		$self->{errstr} = $reply->status_line;
		return;
	}

	my $raw_json = $reply->decoded_content;
	my $json     = decode_json($raw_json);

	my $is_route_pre = 1;
	$self->{sched_route}      = [];
	$self->{sched_route_pre}  = [];
	$self->{sched_route_post} = [];

	for my $stop ( @{ $json->{JourneyDetail}{Stops}{Stop} } ) {
		my $stop_obj = {
			station         => $stop->{name},
			station_id      => $stop->{id},
			sched_arrival   => $stop->{arrTime},
			sched_departure => $stop->{depTime},
			platform        => $stop->{track},
		};

		push( @{ $self->{sched_route} }, $stop_obj );

		if ($is_route_pre) {
			if ( $stop->{id} == $self->{station_id} ) {
				$is_route_pre = 0;
			}
			else {
				push( @{ $self->{sched_route_pre} }, $stop_obj );
			}
		}
		else {
			push( @{ $self->{sched_route_post} }, $stop_obj );
		}
	}
}

sub sched_route {
	my ($self) = @_;

	$self->get_detail_json;
	return @{ $self->{sched_route} };
}

sub sched_route_pre {
	my ($self) = @_;

	$self->get_detail_json;
	return @{ $self->{sched_route_pre} };
}

sub sched_route_post {
	my ($self) = @_;

	$self->get_detail_json;
	return @{ $self->{sched_route_post} };
}

1;
