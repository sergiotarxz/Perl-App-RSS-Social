# RSS Social

## Introduction

This is an example of making apps faster using DBIx::Quick and DBIx::Auto::Migrate.

This wants to be a social network focused in the RSS open protocol for user authentication and notification.

It will be developed in my spare time.

The flagship of this project is how it does integrate a GameBoy Advance emulator and a Pokémon
ROMs randomizer to serve as a good base for Randomlocke/Dualocke communities.

<details>
<summary>Featured screenshots, not warranted to be updated</summary>

![](https://raw.githubusercontent.com/sergiotarxz/Perl-App-RSS-Social/refs/heads/main/Screenshots/Screenshot%20From%202026-01-20%2020-08-22.png)

![](https://raw.githubusercontent.com/sergiotarxz/Perl-App-RSS-Social/refs/heads/main/Screenshots/Screenshot%20From%202026-01-20%2020-09-16.png)

![](https://raw.githubusercontent.com/sergiotarxz/Perl-App-RSS-Social/refs/heads/main/Screenshots/Screenshot%20From%202026-01-20%2020-09-26.png)

![](https://raw.githubusercontent.com/sergiotarxz/Perl-App-RSS-Social/refs/heads/main/Screenshots/Screenshot%20From%202026-01-20%2020-09-37.png)

![](https://raw.githubusercontent.com/sergiotarxz/Perl-App-RSS-Social/refs/heads/main/Screenshots/Screenshot%20From%202026-01-20%2020-09-45.png)

![](https://raw.githubusercontent.com/sergiotarxz/Perl-App-RSS-Social/refs/heads/main/Screenshots/Screenshot%20From%202026-01-20%2020-09-55.png)

![](https://raw.githubusercontent.com/sergiotarxz/Perl-App-RSS-Social/refs/heads/main/Screenshots/Screenshot%20From%202026-01-20%2020-10-07.png)

![](https://raw.githubusercontent.com/sergiotarxz/Perl-App-RSS-Social/refs/heads/main/Screenshots/Screenshot%20From%202026-01-20%2020-10-16.png)

![](https://raw.githubusercontent.com/sergiotarxz/Perl-App-RSS-Social/refs/heads/main/Screenshots/Screenshot%20From%202026-01-20%2020-10-28.png)

![](https://raw.githubusercontent.com/sergiotarxz/Perl-App-RSS-Social/refs/heads/main/Screenshots/Screenshot%20From%202026-01-20%2020-12-45.png)

</details>


## Recommended Podman Development setup

### Building the container

```shell
podman build --file Dockerfile  -t rss_social
```

### Setting up the project

#### Setting up the database

You will need a PostgreSQL server, the installation is distribution dependent, so I cannot really
help a lot.

(Your postgresql version may not match ours, but don't worry)

Once you have your PostgreSQL server setup modify the `/etc/postgresql-18/pg_hba.conf` and add
something like this:

```
host    all             all             192.168.1.69/32         password
```

Replace the IP by your ip, you can get your network IP by `ip a`.

And modify `/etc/postgresql-18/postgresql.conf` and ensure the `listen` directive looks like this:

```
listen_addresses = 'localhost,192.168.1.69'		# what IP address(es) to listen on;
```

#### Create database user and database

Enter your database:

```shell
sudo -u postgres psql
```

And in the root console create the needed things:

```sql
create user rss_social WITH PASSWORD 'secret';
create database rss_social OWNER '<the user you want to create>';
```

#### Tune the app config

Copy the example into the final config and edit it to your liking:

```shell
cp r_s_s-social.example.yml r_s_s-social.yml
vim r_s_s-social.yml
```

### Start playing

Execute the following to start the server in `http://localhost:3333`:

```shell
podman run -p 127.0.0.1:3333:3000 -v .:/var/lib/rss_social/Perl-App-RSS-Social/ --rm -it localhost/rss_social
```

## Some intro:

To do frontend work you will need to edit the following files: `public/css/style.css`, everything under `templates` and `public/js/gba.js`.

To do backend everything is under `lib`.

To improve documentation `README.md` is the only related file but you could also create other kinds of documentation such as `CONTRIBUTORS.md`.

Testing should be made under `t`, nothing is done yet about that, but you can improve this.

