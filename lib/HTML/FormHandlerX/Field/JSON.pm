package HTML::FormHandlerX::Field::JSON;
# ABSTRACT: a script tag which sets a var using JSON C<data>, encoded from perl data supplied via field for L<HTML::FormHandler>.


use Moose;
extends 'HTML::FormHandler::Field::NoValue';
use namespace::autoclean;

use JSON::MaybeXS;
use JavaScript::Minifier::XS qw();

has 'data_key' => ( is => 'rw', isa => 'Str', builder => 'build_data_key', lazy => 1 );
sub build_data_key { HTML::FormHandler::Field::convert_full_name( shift->full_name ) }

has 'data' => (
	is => 'rw',
# 	isa     => 'Str',
	builder => 'build_data',
	lazy    => 1
);
sub build_data { '' }
has 'set_data' => ( isa => 'Str', is => 'ro' );

has 'do_minify' => ( isa => 'Bool', is => 'rw', default => 0 );
has '+do_label' => ( default => 0 );

has 'render_method' => (
	traits    => ['Code'],
	is        => 'ro',
	isa       => 'CodeRef',
	lazy      => 1,
	predicate => 'does_render_method',
	handles   => { 'render' => 'execute_method' },
	builder   => 'build_render_method',
);

sub build_render_method {
	my $self = shift;

	my $set_data = $self->set_data;
	$set_data ||= "data_" . HTML::FormHandler::Field::convert_full_name( $self->full_name );
	return sub { my $self = shift; $self->wrap_data( $self->form->$set_data($self) ); }
	  if ( $self->form && $self->form->can($set_data) );
	return sub {
		my $self = shift;
		return $self->wrap_data( $self->data );
	};
} ## end sub build_render_method

sub _result_from_object {
	my ( $self, $result, $value ) = @_;
	$self->_set_result($result);
	$self->value($value);
	$result->_set_field_def($self);
	return $result;
}

sub wrap_data {
	my $self = shift;

	my $json = $self->deflator( @_ > 1 ? [@_] : $_[0] );
	chomp $json;

	my $data_key = $self->data_key;

	my $javascript = '';
	if ( $data_key =~ m/.+\..+/ ) {    # key contains 'dot' properties, so don't create a var, just set property
		$javascript .= qq{\n  $data_key = $json;};
	} elsif ( $data_key =~ m/.+\.$/ ) {    # key ends with 'dot', so assume data_key is object and field_name is property, don't create a var, just set property
		my $property_key = HTML::FormHandler::Field::convert_full_name( $self->full_name );
		$javascript .= qq{\n  $data_key$property_key = $json;};
	} elsif ( $data_key =~ m/^\..+/ )
	{   # key starts with 'dot', so assume data_key is property and field_name is object, don't create a var, just set property, and assume property is an array
		my $object_key = HTML::FormHandler::Field::convert_full_name( $self->full_name );
		$javascript .= qq{\n  $object_key$data_key = $json;};
	} else {
		$javascript .= qq{\n  var $data_key = $json;};
	}

	my $output = qq{\n<script type="text/javascript">};
	$output .= $self->do_minify ? JavaScript::Minifier::XS::minify($javascript) : $javascript;
	$output .= qq{\n</script>};

	return $output;
} ## end sub wrap_data


has "json_opts" => (
	is      => "rw",
	traits  => ['Hash'],
	isa     => "HashRef",
	default => sub { { pretty => undef, relaxed => undef, canonical => undef } },
	handles => {
		set_json_opt => 'set',
		get_json_opt => 'get',
	},
);

sub deflator {
	my ( $self, $value ) = @_;
	my $pretty    = $self->get_json_opt('pretty')    // 1;
	my $relaxed   = $self->get_json_opt('relaxed')   // 1;
	my $canonical = $self->get_json_opt('canonical') // 1;
	return JSON->new
					->utf8
					->allow_nonref
					->pretty($pretty)
					->relaxed($relaxed)
					->canonical($canonical)
					->encode($value)
			 || '';
} ## end sub deflator


__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__
 
=pod
 
=encoding UTF-8
 
=head1 SYNOPSIS
 
This class can be used for fields that need to supply JSON data for use
by scripts in the form. It will JSONify and render the value returned by
a form's C<data_[field_name]> method, or the field's C<data> attribute.
 
  has_field 'user_addresses' => ( type => 'JSON',
     data => { john => 'john@example.com', sarah => 'sarah@example.com' } );
 
or using a method:
 
  has_field 'user_addresses' => ( type => 'JSON' );
  sub data_user_addresses {
     my ( $self, $field ) = @_;
     if( $field->value == 'foo' ) {
        return { john => 'john@example.com', sarah => 'sarah@example.com' };
     } else {
        return [ 'john@example.com', 'sarah@example.com' ];
     }
  }
  #----
  has_field 'usernames' => ( type => 'JSON' );
  sub data_usernames {
      my ( $self, $field ) = @_;
      return [ qw'john sarah' ];
  }
 
or set the name of the rendering method:
 
   has_field 'user_addresses' => ( type => 'JSON', set_data => 'my_user_addresses' );
   sub my_user_addresses {
     ....
   }
 
or provide a 'render_method':
 
   has_field 'user_addresses' => ( type => 'JSON', render_method => \&render_user_addresses );
   sub render_user_addresses {
       my $self = shift;
       ....
       return '...';
   }

=head2 variable names

By default, the name of the variable being assigned is same as the field
name. The variable name can be changed with the data_key attribute. If
the data_key value is simple string (no dot separator) then the variable
will be created with C<var varName;>, otherwise it is assumed the
variable is already defined.

The data_key can begin or end with a dot, in which case the field name
is either appended or prepended to the data_key.

  has_field 'user_addresses' => ( type => 'JSON',
  		data_key => '.email',
  		data_ => [ qw'john@acme.org sarah@acme.org' ],
   );

Will render as:

  <script type="text/javascript">
	user_addresses.email = [ "john@acme.org", "sarah@acme.org" ];
  </script>);

=head1 FIELD OPTIONS

We support the following additional field options, over what is inherited from
L<HTML::FormHandler::Field>

=head2 do_minify

Boolean to indicate whether code should be minified using L<JavaScript::Minifier::XS>

=head2 json_opts

Hashref with 3 possible keys; C<pretty>, C<relaxed>, C<canonical>. The
values are passed to L<JSON> when encoding the data.


=cut
