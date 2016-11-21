defmodule UpsideDownLeds.Registry do
  use GenServer

  ## client API

  @doc """
  Starts the registry.
  """
  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  @doc """
  Displays the string on the LEDs.

  Returns `{:ok, pid}` on success, `:error` otherwise.
  """
  def puts(server, str) do
    GenServer.call(server, {:puts, str})
  end

  ## server callbacks

  def init(:ok) do
    {
      :ok,
      %{
        "A" => 4,
        "B" => 2,
        "C" => 27,
        "D" => 22,
        "E" => 26,
        "F" => 19,
        "G" => 13,
        "H" => 6,
        "I" => 5,
        "J" => 11,
        "K" => 9,
        "L" => 10,
        "M" => 3,
        "N" => 14,
        "O" => 15,
        "P" => 8,
        "Q" => 18,
        "R" => 23,
        "S" => 21,
        "T" => 17,
        "U" => 24,
        "V" => 25,
        "W" => 7,
        "X" => 12,
        "Y" => 16,
        "Z" => 20,
      } |> Enum.map(fn pair -> {letter, pin_no} = pair; {:ok, pid} = Gpio.start_link(pin_no, :output); {letter, pid} end)
        |> Enum.into(%{})
    }
  end

  def handle_call({:puts, str}, _from, pin_map) do
    str
      |> String.to_charlist
      |> Enum.each(fn letter -> pid = pin_map[to_string([letter])]; blink(pid); end)

    {:reply, str, pin_map}
  end

  defp blink(pid, delay_during \\ 500, delay_after \\ 500) do
    Gpio.write(pid, 1)
    :timer.sleep(delay_during)
    Gpio.write(pid, 0)
    :timer.sleep(delay_after)
  end
end
