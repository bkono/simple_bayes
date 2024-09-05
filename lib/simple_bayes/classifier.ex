defmodule SimpleBayes.Classifier do
  alias SimpleBayes.{Classifier.Probability, Tokenizer, Trainer.TokenStemmer}

  require Logger

  def classify_one(pid, string, opts) do
    classify(pid, string, opts) |> Enum.at(0) |> elem(0)
  end

  def classify(pid, string, opts) do
    data = Agent.get(pid, & &1)
    opts = Keyword.merge(data.opts, opts)

    data
    |> Probability.for_collection(opts[:model], category_map(string, opts))
    |> Enum.sort_by(fn {_, score} -> -score end)
    |> take_top(opts[:top])
  end

  def classify_with_threshold(pid, string, opts) do
    results = classify(pid, string, opts)
    threshold = opts[:threshold] || 1.1

    case results do
      [{top_category, top_score}, {runner_up_category, runner_up_score} | _] ->
        log_ratio = safe_log_ratio(top_score, runner_up_score)

        Logger.info(
          "Top: #{inspect({top_category, top_score})}, Runner up: #{inspect({runner_up_category, runner_up_score})}"
        )

        Logger.info("Log ratio: #{log_ratio}")

        if log_ratio < :math.log(threshold) do
          Logger.info(
            "Classification too close to call: #{inspect({top_category, top_score})} vs #{inspect({runner_up_category, runner_up_score})}"
          )

          {:uncertain, results}
        else
          {:ok, top_category}
        end

      [single_result] ->
        {:ok, elem(single_result, 0)}

      [] ->
        {:error, :no_results}
    end
  end

  defp category_map(string, opts) do
    string
    |> Tokenizer.tokenize()
    |> TokenStemmer.stem(opts[:stem])
    |> Tokenizer.map_values(opts[:smoothing])
  end

  defp take_top(result, nil), do: result

  defp take_top(result, num) when is_integer(num) do
    Enum.take(result, num)
  end

  defp safe_log_ratio(top_score, runner_up_score) do
    cond do
      top_score == 0.0 and runner_up_score == 0.0 ->
        # If both scores are zero, consider them equal
        0.0

      top_score == 0.0 ->
        # If top score is zero but runner-up isn't, consider it infinitely less likely
        -:infinity

      runner_up_score == 0.0 ->
        # If runner-up is zero but top score isn't, consider it infinitely more likely
        :infinity

      true ->
        :math.log(top_score) - :math.log(runner_up_score)
    end
  end
end
