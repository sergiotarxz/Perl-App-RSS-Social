package RSS::Social::MessageFormatter;

use v5.42.0;
use strict;
use warnings;

use Moo;
use Mojo::Template;
use RSS::Social::Wiki;

has _templater => ( is => 'lazy' );
has _parser    => ( is => 'lazy' );
has _template  => ( is => 'lazy' );

sub _build__templater {
    my $self = shift;
    return Mojo::Template->new( auto_escape => 1 );
}

sub _build__parser {
    my $self = shift;
    return RSS::Social::Wiki->singleton;
}

sub _build__template {
    return <<'EOF';
% my @tags = @_;
% for my $tag (@tags) {
<%   if (!ref $tag) {
        %><%= $tag %><%
       next;
   } 
   if ($tag->{status} eq 'open') {
        %><<%=$tag->{tag}%><%
        for my $attr (keys %{$tag->{attrs}}) { 
            %> <%=$attr%>="<%=$tag->{attrs}{$attr}%>"<%
         } %>><%
   }
   if ($tag->{status} eq 'close') {
        %></<%=$tag->{tag}%>><%
   }
 }
%>
EOF
}

sub render {
    my ( $self, $message ) = @_;
    return $self->render_text($message->text);
}

sub render_text {
    my ( $self, $text ) = @_;
    my @tags     = @{$self->_parser->parse( $text )};
    my $template = $self->_template;
    return $self->_templater->render( $template, @tags );
}
1;
