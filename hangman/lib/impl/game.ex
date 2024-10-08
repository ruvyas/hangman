defmodule Hangman.Impl.Game do
  alias Hangman.Type

  ## defstruct
  @type t :: %__MODULE__{
          game_state: Type.state(),
          letters: list(String.t()),
          turns_left: integer,
          used: MapSet.t(String.t())
        }

  defstruct(
    turns_left: 7,
    game_state: :initializing,
    letters: [],
    used: MapSet.new()
  )

  #########################################
  @spec init_game() :: t
  def init_game do
    init_game(Dictionary.random_word())
  end

  @spec init_game(String.t()) :: t
  def init_game(word) do
    %__MODULE__{
      letters: word |> String.codepoints()
    }
  end

  #########################################

  @spec make_move(t, String.t()) :: {t, Type.tally()}
  def make_move(game = %{game_state: state}, _guess)
      when state in [:won, :lost] do
    game |> return_with_tally()
  end

  def make_move(game, guess) do
    accept_guess(game, guess, MapSet.member?(game.used, guess))
    |> return_with_tally()
  end

  def tally(game) do
    %{
      turns_left: game.turns_left,
      game_state: game.game_state,
      letters: reveal_guessed_letters(game),
      used: game.used |> MapSet.to_list() |> Enum.sort()
    }
  end

  #########################################

  defp accept_guess(game, _guess, _already_used = true) do
    %{game | game_state: :already_used}
  end

  defp accept_guess(game, guess, _already_used) do
    %{game | used: MapSet.put(game.used, guess)}
    |> score_guess(Enum.member?(game.letters, guess))
  end

  defp return_with_tally(game) do
    {game, tally(game)}
  end

  defp score_guess(game, _good_guess = true) do
    # if we have guess all the letters, game has been won
    # else good guess
    new_state =
      MapSet.subset?(MapSet.new(game.letters), game.used)
      |> maybe_won()

    %{game | game_state: new_state}
  end

  defp score_guess(game = %{turns_left: 1}, _bad_guess) do
    # turns_left == 1 -> lost | dec turns_left, :bad_guess
    %{game | game_state: :lost, turns_left: 0}
  end

  defp score_guess(game, _bad_guess) do
    # turns_left == 1 -> lost | dec turns_left, :bad_guess
    %{game | game_state: :bad_guess, turns_left: game.turns_left - 1}
  end

  defp reveal_guessed_letters(game = %{ game_state: :lost }) do
    game.letters
  end

  defp reveal_guessed_letters(game) do
    game.letters
    |> Enum.map(fn letter -> MapSet.member?(game.used, letter) |> maybe_reveal(letter) end)
  end

  defp maybe_won(true), do: :won
  defp maybe_won(_), do: :good_guess

  defp maybe_reveal(true, letter), do: letter
  defp maybe_reveal(_, _letter), do: "_"
end
