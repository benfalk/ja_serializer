defmodule JaSerializer.Builder.Link do
  @moduledoc false

  @param_fetcher_regex ~r/:\w+/

  defstruct href: nil, meta: nil, type: :related

  def build(_context, _type, nil), do: nil

  def build(context, type, path) when is_binary(path) do
    %__MODULE__{
      href: path_for_context(context, path),
      type: type
    }
  end

  def build(context, type, path) when is_atom(path) do
    %__MODULE__{
      href: apply(context.serializer, path, [context.data, context.conn]),
      type: type
    }
  end

  def flag_links_for_parsing(opts, rel) do
    Enum.reduce opts[:links] || [], opts, fn
      ({_type, link}, acc) when not(is_binary(link)) -> acc
      ({type , link}, acc) ->
        function_name = String.to_atom("#{rel}_#{type}_link")

        Keyword.put_new(acc, :links_for_parsing, [])
        |> put_in([:links, type], function_name)
        |> put_in([:links_for_parsing, function_name], link)
    end
  end

  def build_functions(links) do
    links
    |> Enum.map(&to_string_definition/1)
    |> Enum.join("\n")
    |> Code.string_to_quoted!
  end

  defp to_string_definition({name, template}) do
    interpolated = "\"#{String.replace(template, ~r/:(\w+)/, "\#{\\1(data, conn)}")}\""
    args = if String.match?(template, ~r/:(\w+)/), do: "data, conn", else: "_, _"

    """
    def #{name}(#{args}), do: #{interpolated}
    defoverridable [{:#{name}, 2}]
    """
  end

  defp path_for_context(context, path) do
    @param_fetcher_regex
    |> Regex.replace(path, &frag_for_context(&1, context))
  end

  defp frag_for_context(":" <> frag, %{serializer: serializer} = context) do
    "#{apply(serializer, String.to_atom(frag), [context.data, context.conn])}"
  end
end
