defmodule SimpleBayes.Trainer do
  alias SimpleBayes.Trainer.{
    TokenParser,
    TokenRecorder,
    TokenCataloger,
    TrainingCounter
  }

  def train(pid, category, string, opts) do
    Agent.get_and_update(pid, fn state ->
      opts = Keyword.merge(state.opts, opts)

      new_state =
        state
        |> TokenParser.parse(string, opts)
        |> TokenRecorder.record(category, opts)
        |> TokenCataloger.catalog(category, opts)
        |> TrainingCounter.increment()
        |> update_category_count(category)
        |> update_vocabulary()

      {state, new_state}
    end)

    pid
  end

  defp update_category_count(state, category) do
    cat_data = state.categories[category] || [trainings: 0, tokens: %{}]
    updated_cat_data = Keyword.update!(cat_data, :trainings, &(&1 + 1))
    %{state | categories: Map.put(state.categories, category, updated_cat_data)}
  end

  defp update_vocabulary(state) do
    vocab =
      state.categories
      |> Enum.flat_map(fn {_, cat_data} -> Map.keys(cat_data[:tokens]) end)
      |> Enum.uniq()
      |> Enum.map(&{&1, 0})
      |> Map.new()

    %{state | tokens: vocab}
  end
end
