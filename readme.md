# komrade api

This app is responsible to handeling the provisioning requets made by heroku addons. It also serves the komrade dashboard. Both of these tasks require the komrade api to have access to the komrade database.

## local setup

```bash
$ export $(cat sample.env)
$ bundle install
# Queue Management Database
$ dropdb komrade
$ createdb komrade
$ pg_dump $(heroku config -a komrade-store -s | grep "^DATABASE_URL" | sed 's/DATABASE_URL=//') -s --no-acl --no-owner | psql komrade
$ psql komrade -c "insert into queues (heroku_id) values ('`whoami`');"
# Queue Statistics Database
$ dropdb komrade-stats
$ createdb komrade-stats
$ pg_dump $(heroku config -a komrade-store -s | grep "^STATS_DATABASE_URL" | sed 's/STATS_DATABASE_URL=//') -s --no-acl --no-owner | psql komrade-stats
$ bundle exec bin/web
```
