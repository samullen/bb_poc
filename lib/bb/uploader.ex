defmodule Bb.Uploader do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  @impl GenServer
  def init(_) do
    body = File.read!("file.txt")
    sha1 = :crypto.hash(:sha, body) |> Base.encode16
    {token, upload_url} = fetch_upload_key()

    {:ok, %{token: token, upload_url: upload_url, body: body, sha1: sha1}}
  end

  @impl GenServer
  def handle_call({:upload, id}, _from, state) do
    upload_id(id, state)
  end

  def upload_id(id, state) do
    headers = [
      {"Authorization", state.token},
      {"X-Bz-File-Name", "file#{id}.txt"},
      {"Content-Type", "text/plain"},
      {"X-Bz-Content-Sha1", state.sha1}
    ]
    options = [
      ssl: [{:versions, [:'tlsv1.2']}],
      recv_timeout: 30_000,
      hackney: [pool: :default]
    ]

    case HTTPoison.post(state.upload_url, state.body, headers, options) do
      {:ok, %{status_code: 200} = status} ->
        {:reply, {:ok, id}, state}

      {:ok, %{status_code: 400}} ->
        IO.puts "400: refreshing for #{inspect self()}"
        new_state = refresh(state)
        upload_id(id, new_state)

      {:ok, %{status_code: 403}} ->
        IO.puts "403: refreshing for #{inspect self()}"
        new_state = refresh(state)
        upload_id(id, new_state)

      {:ok, %{status_code: 503}} ->
        IO.puts "503: refreshing for #{inspect self()}"
        new_state = refresh(state)
        upload_id(id, new_state)

      {:error, %{reason: :checkout_timeout}} ->
        IO.puts "timeout: retrying #{inspect self()}"
        upload_id(id, state)
    end
  end

  def refresh(state) do
    {token, upload_url} = fetch_upload_key()

    %{state | token: token, upload_url: upload_url}
  end

  defp fetch_upload_key() do
    app_id = Application.fetch_env!(:bb, :bb_app_id)
    app_key = Application.fetch_env!(:bb, :bb_app_key)

    authorize()
    |> upload_key()
  end

  defp authorize do
    url = "https://api.backblazeb2.com/b2api/v2/b2_authorize_account"
    app_id = Application.fetch_env!(:bb, :bb_app_id)
    app_key = Application.fetch_env!(:bb, :bb_app_key)
    authorization = Base.encode64("#{app_id}:#{app_key}")

    HTTPoison.get!(url, [{"Authorization", "Basic #{authorization}"}])
    |> handle_response()
  end

  defp upload_key(%{"allowed" => %{"bucketId" => bucket_id}, "authorizationToken" => token, "apiUrl" => url}) do
    upload_url = "#{url}/b2api/v2/b2_get_upload_url?bucketId=#{bucket_id}"

    response =
      HTTPoison.get!(upload_url, [{"Authorization", token}])
      |> handle_response()

    {response["authorizationToken"], response["uploadUrl"]}
  end

  defp handle_response(%HTTPoison.Response{body: body, status_code: 200}) do
    Jason.decode!(body)
  end
end
