ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    # Live tests run in one process so they do not open many OPAC sessions at once.
    parallelize(workers: ENV["OPAC_LIVE"] ? 1 : :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

class ActiveSupport::TestCase
  def opac_fixture(name)
    file_fixture("opac/#{name}.html").read
  end

  def with_opac_host(host)
    original, Opac::Session.host = Opac::Session.host, host
    yield
  ensure
    Opac::Session.host = original
  end
end
