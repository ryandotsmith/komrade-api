# komrade api

This app is responsible to handeling the provisioning requets made by heroku addons. It also serves the komrade dashboard. Both of these tasks require the komrade api to have access to the komrade database.

## local setup

```bash
$ export $(cat sample.env)
$ bundle install
$ bundle exec bin/web
```
