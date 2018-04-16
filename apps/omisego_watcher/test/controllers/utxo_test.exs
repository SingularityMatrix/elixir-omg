defmodule OmiseGOWatcherWeb.Controller.UtxoTest do
  use ExUnitFixtures
  use ExUnit.Case, async: false

  use Plug.Test

  alias OmiseGOWatcherWeb.Controller.Utxo
  alias OmiseGO.API.{Block}
  alias OmiseGO.API.State.{Transaction, Transaction.Signed}

  @moduletag :watcher_tests

  @empty %Transaction{
    blknum1: 0,
    txindex1: 0,
    oindex1: 0,
    blknum2: 0,
    txindex2: 0,
    oindex2: 0,
    newowner1: "",
    amount1: 0,
    newowner2: "",
    amount2: 0,
    fee: 0
  }

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(OmiseGOWatcher.Repo)
  end

  describe "UTXO database." do
    test "No utxo are returned for non-existing addresses." do
      assert get_utxo("cthulhu") == %{"utxos" => [], "address" => "cthulhu"}
    end

    test "Consumed block contents are available." do
      Utxo.consume_block(
        %Block{
          transactions: [
            @empty |> Map.merge(%{newowner1: "McDuck", amount1: 1947}) |> signed,
            @empty |> Map.merge(%{newowner1: "McDuck", amount1: 1952}) |> signed
          ]
        },
        2
      )

      %{"address" => "McDuck", "utxos" => [%{"amount" => amount1}, %{"amount" => amount2}]} =
        get_utxo("McDuck")

      assert Enum.sort([amount1, amount2]) == [1947, 1952]
    end

    test "Spent utxos are moved to new owner." do
      Utxo.consume_block(
        %Block{
          transactions: [
            @empty |> Map.merge(%{newowner1: "Ebenezer", amount1: 1843}) |> signed,
            @empty |> Map.merge(%{newowner1: "Matilda", amount1: 1871}) |> signed
          ]
        },
        1
      )

      %{"utxos" => [%{"amount" => 1871}]} = get_utxo("Matilda")

      Utxo.consume_block(
        %Block{
          transactions: [
            @empty
            |> Map.merge(%{
              newowner1: "McDuck",
              amount1: 1000,
              blknum1: 1,
              txindex1: 1,
              oindex1: 0
            })
            |> signed
          ]
        },
        2
      )

      %{"utxos" => [%{"amount" => 1000}]} = get_utxo("McDuck")
      %{"utxos" => []} = get_utxo("Matilda")
    end

    test "Deposits are a part of utxo set." do
      assert %{"utxos" => []} = get_utxo("Leon")
      Utxo.record_deposits([%{owner: "Leon", amount: 1, block_height: 1}])
      assert %{"utxos" => [%{"amount" => 1}]} = get_utxo("Leon")
    end

    test "Deposit utxo are moved to new owner if spent " do
      assert %{"utxos" => []} = get_utxo("Leon")
      assert %{"utxos" => []} = get_utxo("Matilda")
      Utxo.record_deposits([%{owner: "Leon", amount: 1, block_height: 1}])
      assert %{"utxos" => [%{"amount" => 1}]} = get_utxo("Leon")

      spent = %{
        newowner1: "Matilda",
        amount1: 1,
        blknum1: 1,
        txindex1: 0,
        oindex1: 0
      }

      Utxo.consume_block(
        %Block{
          transactions: [
            @empty
            |> Map.merge(spent)
            |> signed
          ]
        },
        2
      )

      assert %{"utxos" => []} = get_utxo("Leon")
      assert %{"utxos" => [%{"amount" => 1}]} = get_utxo("Matilda")
    end
  end

  defp get_utxo(address) do
    request = conn(:get, "account/utxo?address=#{address}")
    response = request |> send_request
    assert response.status == 200
    Poison.decode!(response.resp_body)
  end

  defp signed(transaction) do
    %Signed{raw_tx: transaction}
  end

  defp send_request(conn) do
    conn
    |> put_private(:plug_skip_csrf_protection, true)
    |> OmiseGOWatcherWeb.Endpoint.call([])
  end
end