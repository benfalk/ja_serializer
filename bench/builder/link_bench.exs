defmodule Builder.LinkBench do
  alias JaSerializer.Builder.Link
  use Benchfella

  bench "with a binary",
    [context: context()],
    do: Link.build(context, :related, "/widget/:id")

  bench "with an atom",
    [context: context()],
    do: Link.build(context, :related, :id_href)

  defmodule Serializer do
    def id(%{id: id}, _), do: id 
    def id_href(%{id: id}, _), do: "/widget/#{id}"
  end

  defp context, do: %{serializer: Serializer, data: %{id: 1}, conn: nil}
end
