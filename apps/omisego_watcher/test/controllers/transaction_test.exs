defmodule OmiseGOWatcherWeb.Controller.TransactionTest do
  use ExUnitFixtures
  use ExUnit.Case, async: false
  use OmiseGO.API.Fixtures
  use Plug.Test

  alias OmiseGO.API.Block
  alias OmiseGO.API.State.Transaction.{Recovered, Signed}
  alias OmiseGOWatcher.TransactionDB

  @eth OmiseGO.API.Crypto.zero_address()

  @tag fixtures: [:phoenix_ecto_sandbox]
  test "insert and retrive transaction" do
    txblknum = 0
    txindex = 0
    recovered_tx = OmiseGO.API.TestHelper.create_recovered([], @eth, [])
    {:ok, %TransactionDB{txid: id}} = TransactionDB.insert(recovered_tx.signed_tx, txblknum, txindex)
    expected_transaction = create_expected_transaction(id, recovered_tx, txblknum, txindex)
    assert expected_transaction == delete_meta(TransactionDB.get(id))
  end

  @tag fixtures: [:phoenix_ecto_sandbox, :alice, :bob]
  test "insert and retrive block of transactions ", %{alice: alice, bob: bob} do
    txblknum = 0
    recovered_tx1 = OmiseGO.API.TestHelper.create_recovered([{2, 3, 1, bob}], @eth, [{alice, 200}])
    recovered_tx2 = OmiseGO.API.TestHelper.create_recovered([{1, 0, 0, alice}], @eth, [])

    [{:ok, %TransactionDB{txid: txid_1}}, {:ok, %TransactionDB{txid: txid_2}}] =
      TransactionDB.insert(%Block{
        transactions: [
          recovered_tx1,
          recovered_tx2
        ],
        number: txblknum
      })

    assert create_expected_transaction(txid_1, recovered_tx1, txblknum, 0) == delete_meta(TransactionDB.get(txid_1))
    assert create_expected_transaction(txid_2, recovered_tx2, txblknum, 1) == delete_meta(TransactionDB.get(txid_2))
  end

  defp create_expected_transaction(
         txid,
         %Recovered{signed_tx: %Signed{raw_tx: transaction, sig1: sig1, sig2: sig2}},
         txblknum,
         txindex
       ) do
    %TransactionDB{
      txblknum: txblknum,
      txindex: txindex,
      txid: txid,
      sig1: sig1,
      sig2: sig2
    }
    |> Map.merge(Map.from_struct(transaction))
    |> delete_meta
  end

  defp delete_meta(%TransactionDB{} = transaction) do
    Map.delete(transaction, :__meta__)
  end
end
