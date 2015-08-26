defmodule OpenAperture.Notifications.Mailer do
  @moduledoc """
  Wraps functionality of Mailman for sending email notifications easily.
  """

  require Logger
  alias   OpenAperture.Notifications.Configuration

  @doc """
  Proxies to Mailman.deliver\2 and suppying necessary configuration params.
  """
  @spec deliver(list, String.t, String.t) :: {:ok, String.t} | {:error, String.t}
  def deliver(addresses, subj, text) do
    addresses = validate_email(addresses)

    if Enum.empty? addresses do
      {:error, "No valid email addresses detected"}
    else
      from = Application.get_env(:mailer, :from)
      Logger.info("Sending email notification(s) to #{inspect addresses} as #{from}, context (#{inspect context})...")
      %Mailman.Email{
        subject: subj,
        from:    from,
        to:      addresses,
        text:    text
      }
        |> Mailman.deliver(context)
        |> Task.await
    end
  end

  @doc false
  defp context do
    %Mailman.Context{
      config:   Configuration.smtp,
      composer: %Mailman.EexComposeConfig{}
    }
  end

  @doc false
  defp validate_email(addresses) when is_list(addresses) do
    sieve = ~r/[A-Za-z0-9.%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}/
    Enum.filter(addresses, &(&1 =~ sieve))
  end
end
