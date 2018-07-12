defmodule OmiseGOWatcher.TransactionDB do
  @moduledoc """
  Ecto Schema representing TransactionDB.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias OmiseGO.API.Block
  alias OmiseGO.API.State.{Transaction, Transaction.Recovered, Transaction.Signed}
  alias OmiseGOWatcher.Repo

  @field_names [
    :txid,
    :blknum1,
    :txindex1,
    :oindex1,
    :blknum2,
    :txindex2,
    :oindex2,
    :cur12,
    :newowner1,
    :amount1,
    :newowner2,
    :amount2,
    :txblknum,
    :txindex,
    :sig1,
    :sig2
  ]
  def field_names, do: @field_names

  @primary_key {:txid, :binary, []}
  @derive {Phoenix.Param, key: :txid}
  @derive {Poison.Encoder, except: [:__meta__]}
  schema "transactions" do
    field(:blknum1, :integer)
    field(:txindex1, :integer)
    field(:oindex1, :integer)

    field(:blknum2, :integer)
    field(:txindex2, :integer)
    field(:oindex2, :integer)

    field(:cur12, :string)

    field(:newowner1, :string)
    field(:amount1, :integer)

    field(:newowner2, :string)
    field(:amount2, :integer)

    field(:txblknum, :integer)
    field(:txindex, :integer)

    field(:sig1, :binary)
    field(:sig2, :binary)
  end

  def get(id) do
    __MODULE__
    |> Repo.get(id)
  end

  def find_by_txblknum(txblknum) do
    Repo.all(from(tr in __MODULE__, where: tr.txblknum == ^txblknum, select: tr))
  end

  def insert(%Block{transactions: transactions, number: block_number}) do
    transactions
    |> Stream.with_index()
    |> Enum.map(fn {%Recovered{signed_tx: %Signed{} = signed}, txindex} ->
      insert(signed, block_number, txindex)
    end)
  end

  def insert(
        %Signed{
          raw_tx: %Transaction{} = transaction,
          sig1: sig1,
          sig2: sig2
        } = tx,
        block_number,
        txindex
      ) do
    id = Signed.signed_hash(tx)

    {:ok, _} =
      %__MODULE__{
        txid: id,
        txblknum: block_number,
        txindex: txindex,
        sig1: sig1,
        sig2: sig2
      }
      |> Map.merge(Map.from_struct(transaction))
      |> Repo.insert()
  end

  def changeset(transaction_db, attrs) do
    transaction_db
    |> cast(attrs, @field_names)
    |> validate_required(@field_names)
  end
end
