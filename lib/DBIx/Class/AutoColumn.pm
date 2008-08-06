package DBIx::Class::AutoColumn;

use strict;
use warnings;

our $VERSION = '0.1';

=head1 NAME

DBIx::Class::AutoColumn - DBIx::Class extension to provide values for selected columns via hooks

=head1 DESCRIPTION

this DBIx::Class component allows you to supply hooks for
selected columns in the ResultSource.  these hooks will
subsequently be used to determine the column's value during
INSERT or UPDATE.

=head1 SYNOPSIS

  package My::Schema::Foo;

  __PACKAGE__->load_components('AutoColumn', ..., 'Core');

  __PACKAGE__->add_columns(
      id => {
          data_type         => 'integer',
          size              => 4,
          is_nullable       => 0,
          default_value     => undef,
          is_auto_increment => 1,
          is_foreign_key    => 0
      },
      id_octal => {
          data_type         => 'integer',
          size              => 4,
          is_nullable       => 0,
          default_value     => undef,
          is_auto_increment => 0,
          is_foreign_key    => 0,
          column_value_from => \&bar,
      }
  );

  sub bar
  {
      my $row = shift;

      return sprintf '%lo', $row->id;
  }

=cut

use base 'DBIx::Class';

__PACKAGE__->mk_classdata(__autocolumn_hooks => {});

sub add_columns
{
	my $self = shift;

	$self->next::method(@_);

	foreach my $column ($self->columns) {
		my $info = $self->column_info($column);

		if (my $ref = $info->{column_value_from}) {
			die 'column_value_from MUST be a code reference!'
				if not ref($ref) eq 'CODE';

			my $hooks = $self->__autocolumn_hooks;

			$self->__autocolumn_hooks({ %$hooks, $column => $ref });
		}
	}
}

sub insert
{
	my $self = shift;

	my $hooks = $self->__autocolumn_hooks;

	while (my ($column, $hook) = each %$hooks) {
		my $accessor = $self->column_info($column)->{accessor} || $column;

		$self->$accessor($hook->($self));
	}

	return $self->next::method(@_);
}

sub update
{
	my $self = shift;
	my $href = shift;

	$self->set_columns($href);

	my $hooks = $self->__autocolumn_hooks;

	while (my ($column, $hook) = each %$hooks) {
		my $accessor = $self->column_info($column)->{accessor} || $column;
		$self->$column($hook->($self));
	}

	return $self->next::method({}, @_);
}

1;
