defmodule OpenAperture.Notifications.Mailer.Test do
  use   ExUnit.Case, async: true
  alias OpenAperture.Notifications.Mailer

  setup_all do
    Mailman.TestServer.start && :ok
  end

  test "returns an actual email" do
    {:ok, msg} = Mailer.deliver(
      ["test@test.com"],
      "Test Subject",
      "Test Message"
    )

    assert is_bitstring(msg)
    assert msg =~ ~r/\AFrom:.+/
  end

  test "failes with an invalid email address" do
    {:error, msg} = Mailer.deliver(
      ["test@test"],
      "Test Subject",
      "Test Message"
    )

    assert is_bitstring(msg)
    assert msg == "No valid email addresses detected"
  end
end
