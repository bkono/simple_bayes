defmodule SimpleBayes.Storage.Dets do
  @behaviour SimpleBayes.Storage.Behaviour

  @auto_save_interval 1000

  def init(struct, opts) do
    opts = Keyword.merge(struct.opts, opts)
    open_table(opts)
    struct = %{struct | opts: opts}

    :dets.insert(opts[:table_name], {"data", struct})

    {:ok, pid} = Agent.start_link(fn -> struct end)

    pid
  end

  def save(pid, struct) do
    table_name = struct.opts[:table_name]
    :dets.insert(table_name, {"data", struct})
    :dets.sync(table_name)

    {:ok, pid, nil}
  end

  def load(opts) when is_list(opts) do
    case {Keyword.get(opts, :file_path), Keyword.get(opts, :table_name)} do
      {file_path, table_name} when is_binary(file_path) and is_atom(table_name) ->
        open_table(opts)
        [{_, struct}] = :dets.lookup(table_name, "data")
        init(struct, opts)

      {file_path, nil} when is_binary(file_path) ->
        opts =
          Keyword.put_new(opts, :table_name, String.to_atom(Path.basename(file_path, ".dets")))

        load(opts)

      _ ->
        opts = Keyword.put_new(opts, :file_path, Application.get_env(:simple_bayes, :file_path))
        load(opts)
    end
  end

  defp open_table(opts) do
    table_name = opts[:table_name]
    file_path = String.to_charlist(opts[:file_path])

    :dets.open_file(table_name, file: file_path, auto_save: @auto_save_interval)
  end
end
