require "test_helper"

class SuggestionTest < ActiveSupport::TestCase
  test "corrects each misspelt word with the closest word in the books found" do
    texts = GoogleBooks.texts(file_fixture("google_books/ana_cadabra.json").read)

    assert_equal "anna kadabra", Suggestion.correct("ana cadabra", texts)
  end

  test "keeps the words that appear in the books, ignoring case and accents" do
    texts = [ "La sombra del viento", "Carlos Ruiz Zafón" ]

    assert_equal "La sombra del viento zafon", Suggestion.correct("La sombra del biento zafon", texts)
  end

  test "suggests nothing when every word appears in the books" do
    assert_nil Suggestion.correct("patria aramburu", [ "Patria", "Fernando Aramburu" ])
  end

  test "suggests nothing when no book was found" do
    assert_nil Suggestion.correct("xqzwvkjh", [])
  end

  test "leaves short words and numbers alone" do
    assert_nil Suggestion.correct("la 1984", [ "Le 1985" ])
  end

  test "suggests nothing when Google Books cannot be reached" do
    with_google_books(host: "localhost", api_key: "key") do
      assert_nil Suggestion.for("ana cadabra")
    end
  end

  class LiveTest < ActiveSupport::TestCase
    setup do
      skip "Set GOOGLE_BOOKS_LIVE=1 and RAILS_MASTER_KEY to run tests against Google Books" unless ENV["GOOGLE_BOOKS_LIVE"] && GoogleBooks.api_key
    end

    test "corrects a misspelt title" do
      assert_equal "anna kadabra", Suggestion.for("ana cadabra")
      assert_equal "harry potter", Suggestion.for("harri poter")
    end
  end

  private
    def with_google_books(host:, api_key:)
      original = [ GoogleBooks.host, GoogleBooks.api_key ]
      GoogleBooks.host, GoogleBooks.api_key = host, api_key
      yield
    ensure
      GoogleBooks.host, GoogleBooks.api_key = original
    end
end
