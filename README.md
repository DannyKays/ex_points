# ExPoints
ExPoints is a phoenix api app, with a single endpoint.  The app returns, at most 2 users but it can return 
less users with more than a random number of points.

# Installing / Getting started
To run this project, you will need to install the following dependencies on your system:

  * Elixir v1.13.4 or or newer (you will also need Erlang 23 or later)
  * Phoenix v1.6.13 or newer
  * PostgreSQL v13.6 or newer

To start your Phoenix server:

  * Set the follwing environment variable: `DB_USER=your-database-user` and `DB_PASSWORD=your-database-user-password`
  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Generate user seeds with `mix run priv/repo/seeds.exs`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check the elixir deployment guides](https://hexdocs.pm/phoenix/deployment.html).

# Documentation
To generate the documentation, you can run in your terminal: `mix docs`

# Testing
To run tests, you can run in your terminal: `mix test`

# Style guide
This project uses `mix format`. You can find the configuration file for the formatter in the `.formatter.exs` file.

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
