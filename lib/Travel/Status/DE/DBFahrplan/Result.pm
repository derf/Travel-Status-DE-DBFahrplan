package Travel::Status::DE::DBFahrplan::Result;

use strict;
use warnings;
use 5.010;

use parent 'Class::Accessor';

our $VERSION = '0.00';

Travel::Status::DE::DBFahrplan::Result->mk_ro_accessors(
	qw(train line type date time destination platform));

sub new {
	my ( $obj, %data ) = @_;

	my $ref = {
		train       => $data{name},
		line        => $data{name},
		type        => $data{type},
		date        => $data{date},
		time        => $data{time},
		destination => $data{direction},
		platform    => $data{track},
	};

	return bless( $ref, $obj );
}

1;
