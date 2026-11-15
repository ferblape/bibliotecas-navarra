# A corrected search for searches with few results, which are often misspelt
# ("ana cadabra" for "anna kadabra"). Each word of the search is replaced by the
# closest word in the titles and authors of the books Google Books finds for it.
module Suggestion
  FEW_RESULTS = 3
  # Shorter words and numbers are too easy to "correct" into a different word.
  CORRECTABLE_WORD = /\A[[:alpha:]]{3,}\z/

  extend self

  # Without a correction or when Google Books fails, no suggestion: it is a nicety,
  # never a reason to fail a search.
  def for(query)
    Rails.cache.fetch([ "suggestion", query ], expires_in: 1.day) { correct(query, GoogleBooks.search(query)) }
  rescue GoogleBooks::Unavailable => error
    Rails.logger.warn "No suggestion for #{query.inspect}: #{error.message}"
    nil
  end

  def correct(query, texts)
    words = dictionary(texts)
    spell_checker = DidYouMean::SpellChecker.new(dictionary: words.keys)
    query_words = query.scan(/[[:alnum:]]+/)
    corrected = query_words.map do |word|
      key = normalize(word)
      next word if words.key?(key) || !word.match?(CORRECTABLE_WORD)

      words[spell_checker.correct(key).first] || word
    end
    corrected.join(" ") unless corrected == query_words
  end

  private
    # Words of the books by their normalized form, keeping the first (best match) of each.
    def dictionary(texts)
      texts.flat_map { it.scan(/[[:alnum:]]+/) }.uniq { normalize(it) }.index_by { normalize(it) }.transform_values(&:downcase)
    end

    def normalize(word)
      I18n.transliterate(word).downcase
    end
end
