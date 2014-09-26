# REVS -- Ruby EventSwarm library

This gem provides a set of libraries that provide common capabilities and convenience functions for EventSwarm
applications written in JRuby. See the individual modules and classes for information about each.

We like using JRuby for EventSwarm apps because of the leg-up we get from Rails, Sinatra and other great Ruby
gems/frameworks. The general principle is to use Ruby to connect the components of the processing graph
and provide a UI, but leave the heavy lifting in Java. That said, you can also develop EventSwarm processing
components in Ruby. For example, we have email and SMS sending components in Ruby because of the
templating capabilities. We run these in threads to avoid slowing down the main processing graph.

[Note8](https://note8.com.au) is a JRuby + Rails + EventSwarm application. We use Rails to manage user rules
and alerting configurations, then establish the processing graph necessary to implement the rules in EventSwarm.

## Install

The usual, add it to your Gemfile:

    gem 'revs'

And run `bundle install`. You might need to grab it from github rather than the rubygems server.
If so, use the following in your Gemfile:

    gem 'revs', :git => 'ssh://git@github.com/eventswarm/revs'

The gem references a set of gem-wrapped jar files required for EventSwarm. These are in the git repository and
should be installed automatically by bundler. If you're installing gems manually, take a look at the Gemfile to
see the dependencies.

## Configure
Your application will need a configuration file containing auth tokens, email account details,
email addresses, base URLs etc, depending on the features you want to use.
Use `lib/config/templates/config.yml` as a template then call `AppConfig.init <myconfig.yml>` in a Rails initializer
or from your `config.ru` (Sinatra).

For developers, the unit tests depend on having a `lib/config/config.yml` file. We recommend using a symbolic link
to a file stored outside the repository to avoid accidentally checking in your passwords and tokens.

## Key modules and classes:

* `AddAction/RemoveAction` -- helper class implementing the EventSwarm `AddEventAction` and `RemoveEventAction` and calling a supplied block
* `AddSet/RemoveSet` -- helper class implementing EventSwarm `NewSetAction` and `RemoveSetAction` and calling a supplied block
* `Triggers` -- essential methods for connecting and disconnecting EventSwarm triggers and actions
* `Events` -- provides tests to determine event types
* `Log4JLogger` -- mixin wrapper around log4j so we can implement consistent logging across Java and Ruby components
* `LogConfiguration` -- generates email alerts with escalation based on log4j log output
* `AppConfig` -- simple wrapper around YAML for application config, including Auth tokens for twitter, email etc. See template config file in `config/templates`. A bit ugly: need to refactor.
* `BriefDate` -- abbreviates timestamps relative to current time, e.g. same day just prints time, last week gives day name, preceding weeks give full date
* `Sender` -- parent module for components that send alerts, implementing rate limiting
* `EmailSender` -- sends email using a template
* `SmsSender` -- sends SMS via Clickatell using a template
* `TweetPattern` -- Twitter pattern matching
* `TweetClouds` -- Maintains powersets of tweets suitable for building tag clouds for author, hashtag and mentions
* `TweetStream` -- Manages a twitter stream
* `JsonStream` -- Create events from JSON objects received in HTTP requests (wraps JsonHttpChannel)
* `XmlStream` -- Create events from XML documents received in HTTP requests (wraps XmlHttpChannel)
