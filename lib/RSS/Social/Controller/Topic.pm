package RSS::Social::Controller::Topic;

use v5.42.0;
use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';
use RSS::Social::Topic;
use RSS::Social::Messages;
use RSS::Social::User;
use RSS::Social::Controller::Log;
use UUID qw/uuid4/;

sub view_message {
    my $self         = shift;
    my $slug         = $self->param('topic_slug');
    my $message_uuid = $self->param('message_uuid');
    my ($topic) = @{ RSS::Social::Topic->search(
            slug => $slug,
        )
    };
    if (!defined $topic) {
	    return $self->redirect_to('/');
    }
    my ($message) = @{ RSS::Social::Messages->search(
            uuid => $message_uuid,
        )
    };
    if (!defined $message) {
	    return $self->redirect_to('/rs/'.$topic->slug);
    }
    $self->render(message => $message, topic => $topic);
}

sub visit {
    my ($self)  = @_;
    my $slug    = $self->param('slug');
    my ($topic) = @{ RSS::Social::Topic->search(
            slug => $slug,
        )
    };
    my @messages = @{ RSS::Social::Messages->free_search(
            -where => {
                'messages.id_topic' => $topic->id,
            },
            -limit    => 30,
            -order_by => 'messages.created DESC',
        )
    };
    $self->render( topic => $topic, messages => \@messages );
}

sub get_create_topic {
    my $self = shift;
    $self->render;
}

sub post_create_topic {
    my $self              = shift;
    my $topic_name        = $self->param('topic_name');
    my $topic_slug        = $self->param('topic_slug');
    my $topic_description = $self->param('topic_description');
    if ( $topic_slug !~ /^(?:[a-zA-Z0-9_]|-){5,}$/ ) {
        say 'slug';
        return $self->redirect_to('/private/topic/create');
    }
    if ( 5 > length $topic_name ) {
        say 'name';
        return $self->redirect_to('/private/topic/create');
    }
    if ( 5 > length $topic_description ) {
        say 'description';
        return $self->redirect_to('/private/topic/create');
    }
    my $uuid  = uuid4();
    my $topic = RSS::Social::Topic::Instance->new(
        uuid               => $uuid,
        name               => $topic_name,
        slug               => $topic_slug,
        description        => $topic_description,
        id_user_created_by => $self->user->id,
    );
    RSS::Social::Topic->insert($topic);
    return $self->redirect_to("/rs/@{[$topic->slug]}");
}

sub post_new_message {
    my $self       = shift;
    my $message    = $self->param('message');
    my $topic_uuid = $self->param('topic');
    my ($topic) =
      @{ RSS::Social::Topic->search( uuid => $topic_uuid ) };
    my $uuid = uuid4();
    RSS::Social::Messages->insert(
        RSS::Social::Messages::Instance->new(
            uuid            => $uuid,
            id_topic        => $topic->id,
            id_user_creator => $self->user->id,
            text            => $message
        )
    );
    return $self->redirect_to( '/rs/' . $topic->slug );
}

RSS::Social::Controller::Log->import(qw/visit get_create_topic/);
1;
