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
    my $pattern       = $params{pattern};
    my $title         = $params{title};
    my $required      = $params{required};
    my $br            = $params{br} // 1;
    my $id            = "input-form-$name-@{[$id_counter++]}";
    return (
"<label for=\"@{[xml_escape $id]}\" >@{[xml_escape $description]}: </label>"
          x !!$description )
      . "<input name=\"@{[xml_escape $name]}\" "
      . ( "type=\"@{[xml_escape $type]}\" " x !!$type )
      . ( "class=\"@{[xml_escape $class]}\" " x !!$class )
      . ( "pattern=\"@{[xml_escape $pattern]}\" " x !!$pattern )
      . ( "title=\"@{[xml_escape $title]}\" " x !!$title )
      . ( "id=\"@{[xml_escape $id]}\" " x !!$id )
      . ( "value=\"@{[xml_escape $default_value]}\"" x !!$default_value )
      . ( "required " x !!$required ) . '/>'
      . ( '<br/>' x !!$br );
}

sub textarea {
    my $self          = shift;
    my %params        = @_;
    my $name          = $params{name} or die 'Missing name';
    my $type          = $params{type};
    my $description   = $params{description};
    my $default_value = $params{default_value};
    my $placeholder   = $params{placeholder};
    my $class         = $params{class};
    my $pattern       = $params{pattern};
    my $title         = $params{title};
    my $br            = $params{br};
    my $id            = "textarea-form-$name-@{[$id_counter++]}";
    return (
"<label for=\"@{[xml_escape $id]}\" >@{[xml_escape $description]}: </label>"
          x !!$description )
      . "<textarea rows=\"10\" cols=\"60\" name=\"@{[xml_escape $name]}\" "
      . ( "type=\"@{[xml_escape $type]}\" " x !!$type )
      . ( "class=\"@{[xml_escape $class]}\" " x !!$class )
      . ( "pattern=\"@{[xml_escape $pattern]}\" " x !!$pattern )
      . ( "title=\"@{[xml_escape $title]}\" " x !!$title )
      . ( "placeholder=\"@{[xml_escape $placeholder]}\" " x !!$placeholder )
      . ( "id=\"@{[xml_escape $id]}\" " x !!$id )
      . ">@{[xml_escape($default_value) // '']}</textarea>"
      . ( '<br/>' x !!$br );
}

sub end {
    return '</form>';
}
