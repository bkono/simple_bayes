defmodule SimpleBayes.Classifier.Model.Multinomial do
  alias SimpleBayes.{Accumulator, MapMath, TfIdf}

  def probability_of(categories_map, cat_tokens_map, data) do
    likelihood = likelihood_of(categories_map, cat_tokens_map, data)
    prior = calculate_prior(cat_tokens_map, data)

    :math.exp(likelihood + :math.log(prior))
  end

  defp likelihood_of(categories_map, cat_tokens_map, data) do
    tokens_map = Map.take(cat_tokens_map, Map.keys(categories_map))
    vocab_size = map_size(data.tokens)

    categories_map
    |> Map.merge(tokens_map)
    |> Enum.reduce(0, fn {token, count}, acc ->
      total_count = Accumulator.all(cat_tokens_map)
      prob = (count + 1) / (total_count + vocab_size)
      acc + :math.log(prob)
    end)
  end

  defp calculate_prior(cat_tokens_map, data) do
    cat_docs = Accumulator.all(cat_tokens_map)
    total_docs = data.trainings

    (cat_docs + 1) / (total_docs + map_size(data.categories))
  end
end
