defmodule ExAws.S3.Lazy do
  @moduledoc false
  ## Implimentation of the lazy functions surfaced by ExAws.S3.Client
  def stream_objects!(client, bucket, opts \\ []) do
    request_fun = fn fun_opts ->
      ExAws.S3.Impl.list_objects!(client, bucket, Keyword.merge(opts, fun_opts))
      |> Map.get(:body)
    end

    Stream.resource(fn -> {request_fun, []} end, fn
      :quit -> {:halt, nil}

      {fun, args} -> case fun.(args) do

        results = %{contents: contents, is_truncated: "true"} ->
          {contents, {fun, [marker: next_marker(results)]}}

        %{contents: contents} ->
          {contents, :quit}
      end
    end, &(&1))
  end

  def next_marker(%{next_marker: nil, contents: contents}) do
    contents
    |> List.last
    |> Map.get(:key)
  end
  def next_marker(%{next_marker: marker}), do: marker
end
