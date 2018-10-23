# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule OMG.API.Fixtures do
  use ExUnitFixtures.FixtureModule

  alias OMG.API.Crypto
  alias OMG.API.State.Core
  alias OMG.Eth

  import OMG.API.TestHelper

  deffixture(entities, do: entities())

  deffixture(alice(entities), do: entities.alice)
  deffixture(bob(entities), do: entities.bob)
  deffixture(carol(entities), do: entities.carol)

  deffixture(stable_alice(entities), do: entities.stable_alice)
  deffixture(stable_bob(entities), do: entities.stable_bob)

  deffixture state_empty() do
    {:ok, child_block_interval} = Eth.RootChain.get_child_block_interval()

    {:ok, state} = Core.extract_initial_state([], 0, 0, child_block_interval)
    state
  end

  deffixture state_alice_deposit(state_empty, alice) do
    state_empty
    |> do_deposit(alice, %{amount: 10, currency: Crypto.zero_address(), blknum: 1})
  end

  deffixture state_stable_alice_deposit(state_empty, stable_alice) do
    state_empty
    |> do_deposit(stable_alice, %{amount: 10, currency: Crypto.zero_address(), blknum: 1})
  end
end
