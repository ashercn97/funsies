# funsies

> Use your database with childlike enthusiasm. Its more than fun-- it's funsies!

A fun, type-safe ORM for `Gleam`! (Work in progress, expect big changes! ALSO ASK QUESTIONS IF YOU WANT/NEED/ARE INTERESTED IN ANY OF IT!)

> [!IMPORTANT]
> Now with a CLI! Now, have your schemas automatically generate types and decoders!

These docs are a bit out of date. Will soon be updated.

## About

`Funsies` is a work in progress.

My goal with `funsies` was to create an easy-to-use, friendly ORM for this magical language we call `Gleam`.

I think that Gleam has a ton of potential for the web (with `erlang` and `javascript` targets). But, to date the DB landscape in Gleam is wonderful, but a bit bare-bones.

There are a few great projects (like squirrel) for using raw SQL, and some libraries for generating queries. There were not, however, many libraries for real, full-featured ORMs.

That's what `funsies` is for!

`Funsies` has awesome code-gen abilities, and type-safety, and is (in my opinion) fun to use.

## Usage (with CLI)

`Funsies` works based on Schemas. These schemas are used all the time when using `funsies`.

In the pre-CLI days, you would have to use the provided functions to generate the types and decoders.

This came with a couple of challenges:

- Where do I keep my schemas? Are they separate from the rest of my code?
- How do I create the types and decoders? Should I write a script? Just call a function? Or, worst of all, write it by hand?!

Now, we have a CLI to manage the hard parts! All you do is create a `src/schema` folder. In that folder, you would create a file along the lines of `{schema_name}.gleam` and inside you would make a public function like this:

```gleam
pub fn {schema_name} {
{schema}
}
```

Where schema is the schema you would normally put in your code, and the schema name is the same thing that you put in your file name.

Now, run `gleam run -m funsies` and it will magically generate a new folder (`src/funs`) with files for each and every one of your Schemas!

## Usage

`funsies` is designed to be used with the `gleam_pgo` package for connecting to a postgres database. Currently, it only supports `postgres` database. Eventually I plan for it to support many DBs.

To use funsies, clone the repo, add it to your project, and read through the tutorial below.

## Tutorial

First, set up a database object with the `gleam_pgo` package.

```gleam
  let db =
    pgo.connect(
      pgo.Config(
        ..pgo.default_config(),
        host: "localhost",
        database: "your_db_name",
        user: "db_username",
        port: 5432,
        password: option.Some("db_password"),
        pool_size: 15,
      ),
    )
```

Now, the fun begins!

When using `funsies`, you will be working with `Tables`. Tables are made using the `schema` module, which provides a DSL for building gleam structs that fully represent the table in the database, and are used all over the ORM.

To create a table, use syntax like the following:

```gleam
let user_table =
schema.create_table("table_name")
|> schema.add_serial_column("id") /// This is a column that autoincrements on insert.
|> schema.add_string_column("name", 255) // this represents text
|> schema.add_int_column("age") // this represents an integer
|> schema.add_bool_column("is_active") //this represents a boolean!
```

This table object is POWERFUL. It is used to generate types, to perform queries, etc.

To use this table, we can first perform a migration to create the table in our database. We need to generate the SQL, and then run it (this part I eventually want to make more seamless. Add a PR if you want to help!)

```gleam
let user_table_sql = schema.generate_create_table_sql(user_table)
user_table_sql
|> pgo.execute(db, [], dynamic.dynamic)
```

Now, we have a table in our database!

The next step is to generate some types and decoders. This, as mentioned earlier, uses the table value!

Decoders and types are generated like this:

```gleam
import db/decoder
decoder.generate_row_type(user_table)
decoder.generate_decoder_code(user_table)
```

Then the magic happens! Automatically, you will have a type and decoder generated for you! They will be in the `src/schema` directory, under files named after the table. The type will be named `{table_name}Row{columns}`, and the decoder will be named `{table_name}_decoder_{columns}`. (ALSO WORKING ON THIS TO MAKE NICER NAMES)

Now, we can import our generated types and use them to create an `ORM`.

```gleam
import db/orm
import schema/users6
import schema/users6_decoder

let user_decoder = users6_decoder.users6_decoder_idnameisactive()

let user_orm =
  orm.orm(users6.Users6RowIdNameIsactive, user_table, db, user_decoder) // this is the ORM! The IdNameIsactive is the columns of the table we made earlier. This is so we can have many different types/decoders if we want to select only some columns!
```

Now the ORM can be used to perform queries!

```gleam
let fetched_user_result = user_orm.by_id(2)

io.debug(fetched_user_result)  // This will be serialized into the types you generated earlier! No more messing around with `dynamic` types!

let all_users_result = user_orm.get_all()

io.debug(all_users_result)

let new_user_values = [pgo.text("Asher"), pgo.int(15), pgo.bool(True)] // no ID since auto-increments!

let insert_result = user_orm.insert(new_user_values)

io.debug(insert_result)
```

Magical, right?

Finally, we can use the `yum` DSL to build more complex queries.

```gleam
import db/query/yum

let query =
  yum.new("users6")
  |> yum.select(["name", "is_active"])
  |> yum.where("is_active = TRUE")
  |> yum.to_sql()
```

This will return a string SQL query. To use it, you can generate new types using only the columns you are returning and have it decode into that decoder! Or just use the dynamic type if you want :)

## Contributing

PLEASE CONTRIBUTE! I am new to Gleam, and if there are any improvements, docs, tests, new features, improvements of current features, or anything else you want to contribute, PLEASE make a PR! I would LOVE the help.

THANKS SO MUCH!
