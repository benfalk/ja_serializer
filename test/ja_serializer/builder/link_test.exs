defmodule JaSerializer.Builder.LinkTest do
  use ExUnit.Case

  defmodule ArticleSerializer do
    use JaSerializer

    has_many :comments,
      serializer: JaSerializer.Builder.LinkTest.CommentSerializer,
      link: "comments?article_id=:id"
  end

  defmodule PostSerializer do
    use JaSerializer

    has_many :comments,
      serializer: JaSerializer.Builder.LinkTest.CommentSerializer,
      link: "articles/:id/comments"
  end

  defmodule CommentSerializer do
    use JaSerializer
  end

  defmodule SuperLinkSerializer do
    use JaSerializer
    alias JaSerializer.Builder.Link
    require Link

    attributes [:foo, :bar, :baz]

    has_many :foos, links: [
      related: "bars/:bar/foos/:foo",
      self: ":baz/relationships/bars/:bar"
    ]
  end

  test "id in url path" do
    c1 = %TestModel.Comment{id: "c1", body: "c1"}
    c2 = %TestModel.Comment{id: "c2", body: "c2"}
    a1 = %TestModel.Article{id: "a1", title: "a1", comments: [c1, c2]}

    context = %{data: a1, conn: %{}, serializer: ArticleSerializer, opts: []}
    primary_resource = JaSerializer.Builder.ResourceObject.build(context)

    %JaSerializer.Builder.ResourceObject{
      relationships: [%JaSerializer.Builder.Relationship{:links => [%JaSerializer.Builder.Link{href: href}]}]
    } = primary_resource

    assert href == "comments?article_id=a1"
  end

  test "id in query params" do
    c1 = %TestModel.Comment{id: "c1", body: "c1"}
    c2 = %TestModel.Comment{id: "c2", body: "c2"}
    a1 = %TestModel.Article{id: "a1", title: "a1", comments: [c1, c2]}

    context = %{data: a1, conn: %{}, serializer: PostSerializer, opts: []}
    primary_resource = JaSerializer.Builder.ResourceObject.build(context)

    %JaSerializer.Builder.ResourceObject{
      relationships: [%JaSerializer.Builder.Relationship{:links => [%JaSerializer.Builder.Link{href: href}]}]
    } = primary_resource

    assert href == "articles/a1/comments"
  end

  test "link parsing macro helper" do
    opts = [something: :else,
            links: [related: :related_link, self: "/widgets/:id"]]

    opts = JaSerializer.Builder.Link.flag_links_for_parsing(opts, :widget)
    assert opts[:something] == :else
    assert opts[:links][:related] == :related_link
    assert opts[:links][:self] == :widget_self_link
    assert opts[:links_for_parsing][:widget_self_link] == "/widgets/:id"
  end

  test "function creation of links" do
    data = %{id: '00ic', foo: "4", bar: "7", baz: "berry"}
    assert SuperLinkSerializer.foos_related_link(data, nil) == "bars/7/foos/4"
    assert SuperLinkSerializer.foos_self_link(data, nil) == "berry/relationships/bars/7"
    assert PostSerializer.comments_related_link(data, nil) == "articles/00ic/comments"
    assert ArticleSerializer.comments_related_link(data, nil) == "comments?article_id=00ic"
  end
end
