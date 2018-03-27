### influx_query

This is a gem that provides a minimal chainable DSL for InfluxDB.

### Installation

As usual, either

```
# in the gemfile
gem 'influx_query'
```

or

```
# on the command line
gem install influx_query
```

### Background

However before going into the API it's important to understand the
core concept behind how a query is built.

The `InfluxDB::Client` gem has a method `query` that accepts a string
as its first argument. Queries can of course be written as regular strings and passed to this, but if user-generated values are to be used in the queries, then it is unsafe to directly interpolate them.

Thankfully, the `query` method can do parameterized queries using
the `params` keyword. It looks like this:

```
influxdb_client.query(
  "select * from things where foo=%{val} ;",
  params: { val: "bar" }
)
```

This gem abstracts this away and also makes a chainable dsl.

### Usage

This gem depends on [`influxdb-ruby`](https://github.com/influxdata/influxdb-ruby)
but doesn't come with it included. You should require that gem separately and build
an `InfluxDB::Client` instance using your credentials, as described in their README.

Once you have such a client, you can initialize `InfluxQuery` -
each instance handles only a single query.

```
client = InfluxDB::Client.new(host: "my_host.com")
query = InfluxQuery.new(client: client, source: "things")

# At any point, can call this to see the query
puts query.finalize

# This fires off "SELECT * FROM things":
result = query.resolve

```

`#initialize` accepts some keyword opts in addition to `client` and also makes `attr_reader`s for them. However it is not necessary to manually read/write these since they all have default values set and
are controlled by the chaining dsl.

- `conditions`: an array of strings, such as `"foo = '%{val}'"`.
  These are joined using `AND` when the query is evaluated.
- `params`: the values which will be interpolated into the final query.
- `select_columns`: an array of strings.
  Defaults to `["*"]` and will stay that way unless manually altered.
- `source`: string, the measurement to fetch data from, e.g. "things"

In between `#initialize` and `#resolve`, other methods can be called:

**filter!**

Args:

1. is a key (used internally by `#params`).
2. is a tag/field name.
3. comparison operator
4. value

```
query
  .filter!(:start, "time", "<", "now() - 30d")
  .filter!(:end, "time", ">", "now() - 15d")
```

This previous example has its functionality served by a helper method
as well:

**add_time_filters!**

Args are just `start_time` and `end_time` keywords.

```
query
  .add_time_filters!(
    start_time: "now() - 30d",
    end_time:   "now() - 15d"
  )
```

Influx's SQL-like query language lacks a proper WHERE IN type clause, so
we have to emulate it using something like `WHERE foo=1 OR foo=2 OR foo=3`.
There's a method to help with this:

**add_where_in_filter!**

```
query
  .add_where_in_filter!(:foo, "foo", [1,2,3])
```

Moving on, these should be self explanatory

**limit!**

```
query
  .limit!(500)
```

**offset!**

```
query
  .offset!(250)
```

**group by**

```
query
  .group_by("foo")
```

### Advanced usage

It is possible to use subqueries in conditions, if you manually push those condition strings into `#conditions`.

It is possible to build subqueries using the chaining dsl, if you call
`#finalize_subquery` instead of `#finalize`. This method is actually used by
`#finalize` under the hood. Literally the only the difference is it doesn't
insert a semicolon at the end. It's up to you to add parenthesis around the
subquery as needed.

If you have a subquery you want to include in the main FROM clause, manually set the `source` to point to it.

Please feel free to send an email for help with this.
maxpleaner@gmail.com

