require "test_helper"

class CatalogTest < ActiveSupport::TestCase
  SAN_PEDRO = "BPN/BP21"

  test "raises Unavailable when the OPAC cannot be reached" do
    Rails.cache.clear
    with_opac_host("localhost") do
      assert_raises(Catalog::Unavailable) { Catalog.search("Patria") }
    end
  end

  class LiveTest < ActiveSupport::TestCase
    setup do
      skip "Set OPAC_LIVE=1 to run tests against the real OPAC" unless ENV["OPAC_LIVE"]
    end

    test "searches in every library or in one" do
      everywhere = Catalog.search("Patria")
      san_pedro = Catalog.search("Patria", library: SAN_PEDRO)

      assert_operator everywhere.total, :>, san_pedro.total
      assert_operator san_pedro.total, :>, 0
    end

    test "searches in one field" do
      by_author = Catalog.search("Aramburu", field: :author, library: SAN_PEDRO)
      by_title = Catalog.search("Patria", field: :title, library: SAN_PEDRO)

      assert by_author.records.all? { it.author&.start_with?("Aramburu") }
      assert by_title.records.all? { it.title.match?(/patria/i) }
      assert_operator Catalog.search("Patria", library: SAN_PEDRO).total, :>, by_title.total
    end

    test "returns the requested page" do
      first = Catalog.search("Patria")
      second = Catalog.search("Patria", page: 2)

      assert_equal 2, second.page
      assert_not_equal first.records.map(&:id), second.records.map(&:id)
    end

    test "drops characters the OPAC cannot encode" do
      assert_equal Catalog.search("Patria").total, Catalog.search("Patria 📚").total
    end

    test "finds a record with its copies" do
      record = Catalog.record("554980")

      assert_equal "Patria", record.title
      assert_not_empty record.copies
    end

    test "lists the libraries" do
      assert_includes Catalog.libraries.map(&:code), SAN_PEDRO
    end

    test "serves repeated searches from the cache" do
      with_memory_cache do
        results = Catalog.search("Patria", library: SAN_PEDRO)

        with_opac_host("localhost") do
          assert_equal results, Catalog.search("Patria", library: SAN_PEDRO)
        end
      end
    end

    private
      def with_memory_cache
        cache, Rails.cache = Rails.cache, ActiveSupport::Cache::MemoryStore.new
        yield
      ensure
        Rails.cache = cache
      end
  end
end
