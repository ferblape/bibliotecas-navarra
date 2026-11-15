namespace :libraries do
  desc "Refresh config/libraries.yml from the directory of libraries of navarra.es"
  task import: :environment do
    libraries = LibraryDirectory::Import.new.libraries
    File.write(LibraryDirectory::PATH, <<~YAML + libraries.to_yaml.delete_prefix("---\n"))
      # Written by `bin/rails libraries:import` from https://www.navarra.es/es/bibliotecas/directorio.
      # Do not edit by hand: fix the centres of a library in config/library_overrides.yml.
    YAML

    missing = libraries.select { it["locations"].empty? }.map { it["code"] }
    puts "#{libraries.size} libraries, #{missing.size} without a location: #{missing.join(", ")}"
  end
end
