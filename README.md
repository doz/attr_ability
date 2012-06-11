# AttrAbility

AttrAbility is [CanCan](https://github.com/ryanb/cancan) gem extension that protects ActiveRecord models
from mass assignment based on permissions defined in the CanCan `Ability` class.
It is essentially replacement for `attr_accessible` and `attr_protected` that is designed for projects with variety of user roles.

Ideas behind the project:

* Existing project migration must be as smooth as possible. That is backward compatibility and minimum changes.
* CanCan is de facto standard for authorization, no reason to invent new format for defining abilities.
* Everything which is not explicitly allowed is forbidden.
* There must be easy way to gain full access to model (e.g. from console or seeds).
* Model must know nothing about user roles that have access to it.

## Installation

Add to your Gemfile and run the `bundle` command to install.

```ruby
gem 'attr_ability', :git => 'git://github.com/doz/attr_ability.git'
```

**Requires Ruby 1.9.2 or later.**

## Getting Started

AttrAbility is tightly connected with CanCan. It uses CanCan syntax to define abilities
and extends some of its helper methods to ease integration.

### 1. Configure model attribute abilities

The idea is to assign attributes to actions.
For example, ability to create `Post` means ability to set post `title` and `body`.
While ability to publish `Post` means ability to change `published` attribute to true.

```ruby
class Post < ActiveRecord::Base
  ability :create, [:title, :body]
  ability :publish, [:published]
end
```

### 2. Configure CanCan Ability

You can use existing abilities as well as create custom ones.

```ruby
class Ability
  include CanCan::Ability

  def initialize(user)
    can :create, Post
    if user.is_admin?
      can :publish, Post
    end
  end
end
```

### 3. Update controller to pass current ability to model

If you use default CanCan `load_resource` filter there is nothing to change in controller. AttrAbility will handle it for you.

```ruby
class PostsController < ApplicationController
  load_and_authorize_resource
  ...
end
```

If you have custom code to load resource, update it to pass current ability to the model when you need mass assignment.

```ruby
class PostsController < ApplicationController
  def create
    @post = Post.as(current_ability)
    ...
  end

  def update
    @post = Post.find(params[:id]).as(current_ability)
    ...
  end
end
```

`current_ability` is controller method provided by CanCan.

### 4. Update seeds.rb, etc.

Everything which is not explicitly allowed is considered forbidden.
This means that mass assignment without explicit ability will fail.
`Post.new(:title => "Title")` will create post with nil title.

In controllers you can (and should) use current ability as shown above.
But when you are using rails console or perform system changes (e.g. in seeds.rb)
you usually want to have full access to the model. In this case you can use `as_system` method.

```ruby
Post.as_system.create!(:title => "Title")
post.as_system.update_attributes(:published => true)
```

## Advanced Usage

### CanCan conditions

CanCan provides means to configure conditions to abilities.
AttrAbility validates these conditions against resulting model.

For example, if you want `author_id` attribute of `Post` to be set through mass assignment
you probably doesn't want users to assign their posts to other authors and change other users' posts.
Then you can define ability as follows.

```ruby
class Ability
  include CanCan::Ability

  def initialize(user)
    can [:create, :update], Post, :author_id => user.id
  end
end

class Post < ActiveRecord::Base
  ability :create, [:title, :body, :author_id]
end
```

In this case AttrAbility will allow mass assignment only if `author_id` has correct value.
If user tries to create `Post` with unauthorized `author_id` or change `author_id` of his post he will fail.
From the other hand CanCan will restrict users from updating other users' posts.

### Restrict attribute values

Sometimes you want to restrict some actions to specific attribute values.
For example, if instead of `published` attribute `Post` has `status` attribute with set of values,
you might associate publish action to updating `status` value to "published".
In this case put allowed values to attribute ability definition.

```ruby
class Post < ActiveRecord::Base
  ability :publish, [:status => :published]
end
```

You can mix it with other attributes and define several options.

```ruby
class Post < ActiveRecord::Base
  ability :review, [:reviewier_comment, :status => [:accepted, :rejected]]
end
```

## Compatibility with `attr_accessible` and `attr_protected`

If you define at least one ability in your model, attr_accessible and attr_protected are ignored.

But if your model has no abilities defined, AttrAbility will failback to attr_accessible
and attr_protected definitions to secure your attributes.

This allows for step-by-step migration. If you install AttrAbility and make no configuration,
your application will behave like before without any changes. Then you can replace attr_accessible
with ability configuration model by model.

This also applies to nested attributes assignment. If model configured with AttrAbility accepts nested
attributes for another model that uses attr_accessible, it will behave like expected - root attributes
will be protected according to current ability and nested attributes will be sanitized with attr_accessible.

## Known Issues

Currently AttrAbility is in alpha development stage. It is not released yet and might experience
significant changes before the first release.

* Doesn't suport associations (`post.comments.as(ability)` won't work)
* Not yet tested against Rails other than 3.1
* Lacks matchers for application models testing

## Copyright

Copyright (c) 2012 Alexander Danilenko. See LICENSE.txt for further details.