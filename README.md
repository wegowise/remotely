# Remotely

Remotely lets you specify associations for your models that should
be fetched from a remote API instead of the database.

## App Setup

Apps are where Remotely goes to find association resources. You can define as many as you want, but if you define only one, you can omit the `:app` option from your associations.

    Remotely.app :legsapp, "http://omgsomanylegs.com/api/v1"

## Defining Associations

One app & association name matches URI

    class Millepied < ActiveRecord::Base
      has_many_remote :legs #=> "/legs"
    end

One app & custom path

    class Millepied < ActiveRecord::Base
      has_many_remote :legs, :path => "/store/legs"
    end

One app & custom path with `id` substitution

    class Millepied < ActiveRecord::Base
      has_many_remote :legs, :path => "/millepieds/:id/legs"
    end

Multiple apps (all secondary conditions from above apply)

    class Millepied < ActiveRecord::Base
      has_many_remote :legs, :app => :legsapp, ...
    end

### `id` Substitution

A path can include "`:id`" anywhere in it, which will be replaced by the instance's `id`. This is useful when the resource on the API end is namespaced. For example:

    class Millepied < ActiveRecord::Base
      has_many_remote :legs, :path => "/millepieds/:id/legs"
    end

    m = Millepied.new
    m.id   #=> 1
    m.legs #=> Requests "/millepieds/1/legs"

## Fetched Objects

Remote associations are just array of Struct objects, containing the data returned from the remote API. Being struct objects, they can be access using normal dot notation.

    m = Millepied.new
    m.legs.reduce { |leg| leg.length }

### Fetched Object Associations

If a fetched object includes an attribute matching "\*_id", Remotely tries to find the model it is for and retrieve it.

    leg = m.legs.first
    leg.user_id #=> 2
    leg.user    #=> User.find(2)

## Contributing

Fork, branch and pull-request. Bump versions in their own commit.
