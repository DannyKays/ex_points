# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     ExPoints.Repo.insert!(%ExPoints.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

require Logger
alias ExPoints.Accounts

# Generates and inserts 1,000,000 user seeds.

with {row_count, _return} when row_count < 1 <- Accounts.load_users() do
  raise RuntimeError, message: "An error occurred while loading users. No records inserted"
end
