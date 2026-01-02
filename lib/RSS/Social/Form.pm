package RSS::Social::Form;

use v5.42.0;
use strict;
use warnings;

use Moo;
use Mojo::Util qw/xml_escape/;

my $id_counter = 0;

has action => ( is => 'ro' );
has method => ( is => 'ro' );
has class  => ( is => 'ro' );

sub start {
    my $self = shift;
    return
        "<form "
      . ( "action=\"@{[xml_escape $self->action]}\" " x !!$self->action )
      . ( "method=\"@{[xml_escape $self->method]}\" " x !!$self->method )
      . ( "class=\"@{[xml_escape $self->class]}\"" x !!$self->class ) . '>';
}

sub input {
    my $self          = shift;
    my %params        = @_;
    my $name          = $params{name} or die 'Missing name';
    my $type          = $params{type};
    my $description   = $params{description};
    my $default_value = $params{default_value};
    my $class         = $params{class};
    my $id            = "input-form-$name-@{[$id_counter++]}";
    return
        ("<label for=\"@{[xml_escape $id]}\" >@{[xml_escape $description]}: </label>" x !!$description) . "<input name=\"@{[xml_escape $name]}\" "
      . ( "type=\"@{[xml_escape $type]}\" " x !!$type )
      . ( "class=\"@{[xml_escape $class]}\" " x !!$class )
      . ( "value=\"@{[xml_escape $default_value]}\"" x !!$default_value )
      . '/>' . '<br/>';
}

sub textarea {
    my $self          = shift;
    my %params        = @_;
    my $name          = $params{name} or die 'Missing name';
    my $type          = $params{type};
    my $description   = $params{description};
    my $default_value = $params{default_value};
    my $class         = $params{class};
    my $id            = "textarea-form-$name-@{[$id_counter++]}";
    return
        ("<label for=\"@{[xml_escape $id]}\" >@{[xml_escape $description]}: </label>" x !!$description) . "<textarea rows=\"10\" name=\"@{[xml_escape $name]}\" "
      . ( "type=\"@{[xml_escape $type]}\" " x !!$type )
      . ( "class=\"@{[xml_escape $class]}\" " x !!$class )
      . ">@{[xml_escape($default_value) // '']}</textarea>" . '<br/>';
}

sub end {
    return '</form>';
}
