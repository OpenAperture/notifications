defmodule OpenAperture.Notifications.Mailer.Test do
  use   ExUnit.Case, async: false
  alias OpenAperture.Notifications.Mailer

  test "success" do
    :meck.new(Mailman, [:passthrough])
    :meck.expect(Mailman, :deliver, fn _,_ -> Task.async(fn -> {:ok, ""} end) end)

    {:ok, msg} = Mailer.deliver(
      ["test@test.com"],
      "Test Subject",
      "Test Message"
    )

    assert msg != nil
  after
    :meck.unload(Mailman)
  end

  test "failure" do
    :meck.new(Mailman, [:passthrough])
    :meck.expect(Mailman, :deliver, fn _,_ -> Task.async(fn -> {:error, "bad news bears"} end) end)

    {error, msg} = Mailer.deliver(
      ["test@test.com"],
      "Test Subject",
      "Test Message"
    )

    assert msg != nil
  after
    :meck.unload(Mailman)
  end

  test "fails with an invalid email address" do
    {:error, msg} = Mailer.deliver(
      ["test@test"],
      "Test Subject",
      "Test Message"
    )

    assert is_bitstring(msg)
    assert msg == "No valid email addresses detected"
  end
end
