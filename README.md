# Funsies

> A fun, friendly, and type-safe in-betweensies-ORM for Gleam! Compose type-safe SQL queries, generate decoders and types from schemas, and with a fun CLI!

Full type-safety derived from your schema.

## About

Funsies is a fully type-safe in-betweensies-ORM (?) for Gleam. Obviously, there are other database tools for Gleam. But, I found that most of them felt too barebones for my taste. So, I built the library of my dreams.

Funsies comes with a DSL for schema creation (these schemas are used throughout the rest of the package), a DSL for building queries (with an innovative, stack-based approach), and a CLI for generating boilerplate code from your schemas. All in one, simple package.

The schema allows for type checking, meaning the following will always be true:

- You will not create a query asking for a column of type X to be equal to a value of type Y.
- You will not insert values in the wrong order, or with the wrong types.
- It will be pretty tough to make invalid queries.

## Installation

```bash
gleam add funsies
```

## Usage

> THIS PART OF THE DOCS IS IN PROGRESSSSSSS

To define a schema, create a `schema` folder in your `src` directory. Then, create a `{name}.gleam` file in there, where `{name}` is the name of the schema you're creating. For example, I'd create a `user.gleam` file with the following inside of it:

```gleam
pub fn user() {
  schema.create_table("user")
  |> schema.add_serial_column("id")
  |> schema.add_string_column("name", 255)
  |> schema.add_bool_column("is_active")
}
```

This is where the magic happens! This schema is the brains of your application. It tells Funsies how to create queries, type-check them, and generate pitch-perfect decoders. All with this little, **reusable** definition.

To create the necessary types and decoders, run the following command:

```bash
gleam run -m funsies
```

And thats it! You will now have decoders and types for your schema, as well as an `insert` command that is type-safe and ensures you are passing the correct values in the correct order. The decoders are used from the postgres driver to decode the results of your queries into the generated types. That way, you get easy-to-work-with and type-safe data.

> The ORM/query builder is a work in progress. Below is what we CURRENTLY have.

To create a query, you can use the `yummy` DSL.

For example:

```gleam
import funsies/query/yummy as y
import schema/users
import gleam/io.{debug}

pub fn main() {
  let table = users.users()

  let query =y.new(table)
  |> y.select()
  |> y.where(
    y.wb(table)
    |> y.equals("name", "Alice")
    |> y.not()
    |> y.equals("id", 4)
    |> y.and()
    |> y.equals("id", 5)
    |> y.or()
  )
  |> y.to_sql()

  case query {
    Ok(sql) => debug(sql)
    Error(_) => debug("Error!")
  }
}
```

This might look a bit weird at first. Don't worry! It is natural. Instead of usual composition of functions, we use a stack-based DSL. This allows for a neater, more readable syntax. This yummy query would look like this in a more traditional DSL:

```gleam
y.or(y.and(y.not(y.equals("name", "Alice")), y.equals("id", 4)), y.equals("id", 5))
```

Now, you might see the issue with this "traditional" syntax. It is HARD. TO. READ! Why have an ugly syntax in such a beautiful language?

So, we use the stack-based DSL. It may take a bit of getting used to, but it's worth it!

There are other benefits to our DSL. For example, we have full type-safety. This is because we use the types directly in the DSL to build the query. This means that if you try to add a `String` where a `Bool` is expected, the type-checker will catch it. By expected I mean the type of the column that you are referencing (EVEN THOUGH YOU ARE JUST PASSING A STRING! Magic of the schema :D)

This could look like:

```gleam
|> y.equals("name", 1) // Error, 1 is not a string. It knows that the name value of the column is a string, so it can't be compared to an int.
|> y.equals("is_active", "true") // Error, "true" is not a bool
```

This will be propogated throughout, and you will get an `Error` value for the query instead of an `Ok` value.

While you can still make invalid queries with the yummy DSL, you will not be able to make some common errors (i.e. passing the wrong type of value). This is because funsies checks the schema, sees that the column named "name" is a `String` column, and also sees that you are trying to pass an `Int` to an `equals`. Thus, it will return an error! Pretty cool if I do say so myself 🤓

You can also insert values!

Since you have a Schema, Funsies can generate type-safe insert functions for you! All you have to do is import `insert` from the `funs` (the folder with all the outputs from the codegen).

```gleam
import funs/insert
import funsies/query/yummy as y
import schema/users
import gleam/io.{debug}
import funs/users.{}

pub fn main() {
  let table = users.users()

  let query = y.new(table)
  |> y.insert(users.UsersRow("John", True)) // This is type-safe!
  |> y.to_insert_sql()

  case query {
    Ok(sql) => debug(sql)
    Error(_) => debug("Error!")
  }
}
```

The reason it has to be generated is because of we want full type-safety + good code completeion and help.

## Why do you say `in-betweensies-ORM`?

I don't think `funsies` is a full-on ORM. I took a lot of inspiration from Ecto in the Phoenix/Elixir ecosystem. I think that it is a lot less bare-bones than some existing alternatives, but not as feature-rich (or heavy and difficult to learn) as a typical, traditional ORM.

I'm not sure what to call it! `in-betweensies-ORM`? `micro-ORM`? `mini-ORM`?

## Contributing

Contributions in ANY way are super duper duper appreciated and encouraged! Leaving an issue, starring, or downloading and giving feedback are all amazing.

## Docs

Docs are **in progress**.
