require 'yaml'

namespace :db do
  desc "Run database migrations"
  task migrate: :environment do
    require 'sequel/extensions/migration'
    Sequel::Migrator.apply(DB, "db/migrations")
  end
 
  desc "Rollback the database"
  task rollback: :environment do
    require 'sequel/extensions/migration'
    version = (row = DB[:schema_info].first) ? row[:version] : nil
    Sequel::Migrator.apply(DB, "db/migration", version - 1)
  end
 
  desc "Drop the database"
  task :drop do
    `dropdb "#{db_name}"`
  end

  desc "Create the database"
  task :create do
    `createdb "#{db_name}"`
  end

  desc "Seed the database"
  task seed: :environment do
    require './db/seeds'
  end

  namespace :generate do
    desc 'Generate a timestamped, empty Sequel migration.'
    task :migration, :name do |_, args|
      if args[:name].nil?
        puts 'You must specify a migration name (e.g. rake generate:migration[create_events])!'
        exit false
      end

      content = "Sequel.migration do\n  change do\n    \n  end\nend\n"
      timestamp = Time.now.to_i
      filename = "#{timestamp}_#{args[:name]}.rb"

      Dir.chdir(File.join('db', 'migrations')) do
        File.open(filename, 'w') do |f|
          f.puts content
        end
      end

      puts "Created the migration #{filename}"
    end
  end

  def db_name
    yaml = YAML.load_file(File.join('config', 'database.yml'))
    url = yaml[ENV['RACK_ENV'] || 'development']
    url.split('/')[-1]
  end
end

