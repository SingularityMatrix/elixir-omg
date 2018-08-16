defmodule OmiseGOWatcher.Repo.Migrations.CreateEtheventTable do
  use Ecto.Migration

  def change do
    create table(:ethevents, primary_key: false) do
      add :hash, :binary, primary_key: true
      add :deposit_blknum, :bigint
      add :deposit_txindex, :integer

      # TODO: Pg enumerated type, see: https://github.com/gjaldon/ecto_enum#using-postgress-enum-type
      add :event_type, :integer, null: false
    end
  end
end
