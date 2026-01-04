# RSS Social

## Introduction

This is an example of making apps faster using DBIx::Quick and DBIx::Auto::Migrate.

This wants to be a social network focused in the RSS open protocol for user authentication and notification.

It will be developed in my spare time.

## Prepare the project

Run:

```shell
perl Build.PL
perl Build installdeps
```

## Configuration

Setup a postgresql database accesible with the current user.

```shell
cp r_s_s-social.example.yml r_s_s-social.yml
```

Modify the "/db/dbname" key to match your current postgresql database.

Run the website with

```shell
perl scripts/server.pl
```
