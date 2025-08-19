# Redmine Calendar Subscription Plugin (Redmine 6)

'Calendar Subscription' is a Redmine plugin that helps you keep an overview over planned issues.

It enhances the planning capabilities of Redmine with times and provides ICS calendar subscriptions for projects, filters or the entire Redmine installation.

## Features

* Working iCalendar (ICS) subscriptions of planned tickets
* RSS-key based authentication and optional login-based access
* due date is enhanced with planned finish time
* start time is calculated from planned finish time and estimated hours
* Admin setting to restrict who is allowed to subscribe (user picker)

## Getting the plugin

Most current version is available at: [GitHub](https://github.com/hicknhack-software/redmine_calendar_subscription).

## Requirements

* Redmine 6.x

## Install

1. Follow the Redmine plugin installation steps at `https://www.redmine.org/wiki/redmine/Plugins`. Install to `plugins/redmine_calendar_subscription`
1. Run `bundle install`
1. (If upgrading from older versions) Run migrations: `bundle exec rake redmine:plugins:migrate RAILS_ENV=production`
1. Log into your Redmine as an Administrator
1. Setup the 'subscribe calendar' permissions for your roles
1. Add 'Calendar Subscription' to the enabled modules for your project
1. See 'Usage' for your calendar options

## Update via Git

1. Open a shell to your Redmine's `#{RAILS_ROOT}/plugins/redmine_calendar_subscription` folder
1. Update your git copy with `git pull`
1. Update the database using the migrations: `bundle exec rake redmine:plugins:migrate RAILS_ENV=production`
1. Restart your Redmine

## Usage

Permissions required to perform a calendar subscriptions:

* view the tickets
* the project has the 'Calendar Subscription'-module
* 'subscribe_calendar' permission for the current user
* User must be allowed in plugin settings if a restriction list is configured

If the right permissions are provided, you get access to these calendar subscriptions:

1. On the project overview page you get a calendar link to all open tickets of your poject
1. At the bottom of each tickets list you have the option to create a calendar with the current filter options
1. Top menu 'Projects' - 'Show all issues' allows you to view all the tickets you have access to. At the bottom you can get a link to a calendar as well.

You can take these links and subscribe to them.
See http://mcb.berkeley.edu/academic-programs/seminars/ical-feed-instructions/ for a good instruction set.

### Settings

Go to `Administration -> Plugins -> Redmine Calendar Subscription -> Configure`.

Settings:
* past_days / future_days / maximum_issues
* allowed users: Pick specific users who are allowed to subscribe. If empty, everyone with permission can subscribe.

Subscription options displayed:
* iCal with RSS key: Anonymously accessible using the user's RSS key
* iCal (Login): Requires Redmine login in the client and uses the user's Redmine credentials

## Version History

* 0.4.0 Redmine 6 compatibility, iCalendar 2.x, admin user restrictions, login-based subscription link
* 0.3.1 only issues that do not have children are considered
* 0.3.0 improved compatibility with other plugins
* 0.2.0 improved due_date with time usability with the timepicker plugin
* 0.1.0 initial release (based on an idea from ZwoBit GbR)
