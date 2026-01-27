package RSS::Social;

use v5.42.0;
use strict;
use warnings;

use Mojo::Base 'Mojolicious';
use DateTime::Format::ISO8601;
use DateTime;
use DBD::Pg qw(:pg_types);
use Digest::SHA qw/sha256_hex/;
use UUID        qw/uuid4/;
use Data::Dumper;

sub startup {
    require RSS::Social::Messages;
    my ($self)      = @_;
    my $main_routes = $self->routes;
    my $r           = $main_routes->under(
        '/',
        sub {
            my $c = shift;
        }
    );
    $self->max_request_size(30 * (10 ** 6));
    $r->get('/')->to('Root#index');
    $r->get('/rs/:slug')->to('Topic#visit');
    $r->get('/persist-user')->to('User#persist');
    $r->get('/rss/:uuid/:secret')->to('RSS#private_feed');
    $r->get('/fast-login/:uuid/:secret')->to('User#fast_login');
    $r->get('/profile/:user_identifier')->to('User#public_profile');
    $r->get('/rs/:topic_slug/message/:message_uuid')->to('Topic#view_message');
    $r->get('/rs/:topic_slug/message/:message_uuid/raw')->to('Topic#view_message_raw');
    $r->get('/size', sub {
        my $c = shift;
        my $width = $c->param('width');
        my $height = $c->param('height');
        say "DIMENSIONS ${width}x${height}";
        $c->render( text => 'ok' );
    });
    my $ar = $r->under(
        '/private',
        sub {
            my $c = shift;
            if ( !$c->user ) {
                $c->reply->not_found;
                return undef;
            }
            return 1;
        }
    );
    $ar->get('/topic/create')->to('Topic#get_create_topic');
    $ar->post('/topic/create')->to('Topic#post_create_topic');
    $ar->post('/topic/new-message')->to('Topic#post_new_message');
    $ar->get('/user/profile')->to('User#get_profile');
    $ar->post('/user/username')->to('User#update_username');
    $ar->post('/user/name')->to('User#update_name');
    $ar->post('/user/bio')->to('User#update_bio');
    $ar->post('/message/:uuid/delete')->to('User#delete_message');
    $ar->post('/subscribe')->to('User#subscribe');
    $ar->post('/rss-url/name')->to('RSSUrl#update_name');
    $ar->post('/rss-url/description')->to('RSSUrl#update_description');
    $ar->post('/subscription/delete')->to('User#unsubscribe');
    $ar->get('/rss-url')->to('User#get_rss_urls');
    $ar->get('/message/:message_uuid/edit')->to('Topic#get_edit');
    $ar->post('/topic/edit-message')->to('Topic#post_edit');
    $ar->get('/rom/randomize')->to('Rom#randomize');
    $ar->post('/rom/randomize')->to('Rom#post_randomize');
    $ar->get('/play/:name', sub {
        my $c = shift;
        my $user = $c->user;
        my ($rom) = @{RSS::Social::UserRom->search(id_user => $user->id, name => $c->param('name'))};
        if (!defined $rom) {
            return $c->reply->not_found;
        }
        $c->res->headers->header('Cross-Origin-Opener-Policy', 'same-origin');
        $c->res->headers->header('Cross-Origin-Embedder-Policy', 'require-corp');
        $c->render(
            template    => 'rom/play',
            rom_name    => $c->param('name'),
            save_states => $rom->save_states
        );
    });
    $ar->get('/save/download/:name', sub {
        my $c = shift;
        my $user = $c->user;
        my ($rom) = @{RSS::Social::UserRom->search(id_user => $user->id, name => $c->param('name'))};
        if (!defined $rom) {
            return $c->reply->not_found;
        }
        if (!defined $rom->save) {
            return $c->reply->not_found;
        }
        $c->res->headers->content_disposition('attachment; filename=' . $rom->name.'.sav');
        $c->render( data => $rom->save );
    });
    $ar->post('/save_state/push/:name', sub {
        my $c = shift;
        my $user = $c->user;
        my $save_state = $c->req->upload('save_state');
        my ($rom) = @{RSS::Social::UserRom->search(id_user => $user->id, name => $c->param('name'))};
        if (!defined $rom) {
            return $c->render( text => 'not ok: no rom', code => 400 );
        }
        my $uuid                  = uuid4();
        $save_state = RSS::Social::UserRomSaveState->insert(
            RSS::Social::UserRomSaveState::Instance->new(
                uuid       => $uuid,
                id_rom     => $rom->id,
                save_state => [
                    { dbd_attrs => { pg_type => PG_BYTEA } },
                    $save_state->slurp
                ]
            )
        );
        return $c->render( text => 'ok' );
    });
    $ar->get('/download/save_state/:rom_name/<:uuid>.ss', sub {
        my $c = shift;
        my $user = $c->user;
        my ($rom) = @{RSS::Social::UserRom->search(id_user => $user->id, name => $c->param('rom_name'))};
        if (!defined $rom) {
            return $c->reply->not_found;
        }
        my ($save_state) = @{RSS::Social::UserRomSaveState->search(id_rom => $rom->id, uuid => $c->param('uuid'))};
        if (!defined $save_state) {
            return $c->reply->not_found;
        }
        $c->res->headers->content_type('image/png');
#        $c->res->headers->content_disposition('attachment; filename=' . $rom->name.'.ss');
        $c->render( data => $save_state->save_state );
    });
    $ar->post('/save/push/:name', sub {
        my $c = shift;
        my $user = $c->user;
        my $date = $c->param('date');
        $date = DateTime::Format::ISO8601->parse_datetime($date);
        my $save = $c->req->upload('save');
        my ($rom) = @{RSS::Social::UserRom->search(id_user => $user->id, name => $c->param('name'), last_save => { '<' => $date })};
        if (!defined $rom) {
            return $c->render( text => 'not ok: no rom older save', code => 400 );
        }
        $rom->save([{dbd_attrs => { pg_type => PG_BYTEA }}, $save->slurp]);
        $rom->last_save(DateTime->now);
        RSS::Social::UserRom->update($rom, qw/last_save save/);
        $c->render( text => 'ok (But if you did this manually you are using this web wrong and will lose save data soon or later)' );
    });
    $ar->get('/gba', sub {
        shift->render(template => 'rom/list');
    });
    $ar->get('/rom/upload', sub {
        shift->render(template => 'rom/upload');
    });
    $ar->post('/rom/upload', sub {
        my $c = shift;
        my $user = $c->user;
        my $rom = $c->req->upload('rom');
        my $save = $c->req->upload('save');
        my $name = $c->param('name');
        my $sha_rom = sha256_hex($rom);
        my $uuid                  = uuid4();
        RSS::Social::UserRom->insert(
            RSS::Social::UserRom::Instance->new(
                uuid          => $uuid,
                id_user       => $user->id,
                name          => $name,
                rom_sha256sum => $sha_rom,
                rom => [ { dbd_attrs => { pg_type => PG_BYTEA } }, $rom->slurp ],
                (
                    (defined $save)
                    ? (
                        save => [ { dbd_attrs => { pg_type => PG_BYTEA } }, $save->slurp ],
                    ) : ()
                )
            )
        );
        return $c->redirect_to("/private/play/$name");
    });
    $ar->get('/rom/download/:name', sub {
        my $c = shift;
        my $user = $c->user;
        my ($rom) = @{RSS::Social::UserRom->search(id_user => $user->id, name => $c->param('name'))};
        if (!defined $rom) {
            return $c->reply->not_found;
        }
        $c->res->headers->content_disposition('attachment; filename=' . $rom->name.'.gba');
        $c->render( data => $rom->rom );
    });
    $ar->post('/rom/:name/update_save', sub {
    });
    $r->get('/wasm/mgba.js', sub {
        my $c = shift;
        $c->res->headers->content_type('application/javascript');
        $c->res->headers->header('Cross-Origin-Opener-Policy', 'same-origin');
        $c->res->headers->header('Cross-Origin-Embedder-Policy', 'require-corp');
        my $path = Path::Tiny->new('mgba.js');
        return $c->render(text => $path->slurp_utf8);
    });
    $r->get('/wasm/mgba.wasm', sub {
        my $c = shift;
        $c->res->headers->content_type('application/wasm');
        $c->res->headers->header('Cross-Origin-Opener-Policy', 'same-origin');
        $c->res->headers->header('Cross-Origin-Embedder-Policy', 'require-corp');
        use Path::Tiny;
        my $path = Path::Tiny->new('mgba.wasm');
        return $c->render(data => $path->slurp_raw);
    });
    $self->hook(before_dispatch => sub {
        my $c = shift;
        $c->res->headers->header('Cross-Origin-Opener-Policy', 'same-origin');
        $c->res->headers->header('Cross-Origin-Embedder-Policy', 'require-corp');
    });
    $self->hook(after_static => sub {
        my $c = shift;
        $c->res->headers->header('Cross-Origin-Opener-Policy', 'same-origin');
        $c->res->headers->header('Cross-Origin-Embedder-Policy', 'require-corp');
    });
}

sub new {
    my $class = shift;
    my @args  = @_;
    my $self  = $class->SUPER::new(@_);
    $self->config( $self->plugin('NotYAMLConfig') );
    $self->helper(
        base_url => sub {
            return $self->config->{base_url};
        }
    );
    $self->helper(
        user => sub {
            my $c            = shift;
            my $user_session = $c->user_session;
            return if !$user_session;
            my ($user) = @{ $user_session->users };
            return $user if $user;
            return;
        }
    );
    $self->helper(
        user_session => sub {
            require RSS::Social::UserSession;
            my $c      = shift;
            my $cookie = $c->cookie('auth');
            return if !$cookie;
            my $user_session =
              RSS::Social::UserSession->recover_auth( split '/', "$cookie" );
            return $user_session if defined $user_session;
            return;
        }
    );
    return $self;
}
1;
