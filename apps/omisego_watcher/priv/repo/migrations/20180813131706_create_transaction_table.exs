defmodule OmiseGOWatcher.Repo.Migrations.CreateTransactionTable do
  use Ecto.Migration

  def change do
    create table(:transactions, primary_key: false) do
      add :txhash, :binary, primary_key: true
      add :blknum, :bigint, null: false
      add :txindex, :integer, null: false
      add :txbytes, :binary, null: false
      add :sent_at, :timestamp
      add :eth_height, :bigint
    end

    # TODO: this will work as long as there will be not nulls here
    create unique_index(:transactions, [:blknum, :txindex])
  end
end
