require 'yaml'

namespace :db do
  desc "Run database migrations"
  task :migrate, [:allow_missing] => :environment do |_, args|
    Sequel.extension :migration
    allow_missing = !args[:allow_missing].nil?
    Sequel::Migrator.run(DB, "db/migrations", allow_missing_migration_files: allow_missing)
  end

  desc "Rollback the database"
  task rollback: :environment do
    Sequel.extension :migration
    target = DB[:schema_migrations].reverse_order(:filename).offset(1).first[:filename]
    version = target.match(/^\d+/)[0].to_i
    puts "Rolling back to #{target}"
    Sequel::Migrator.run(DB, "db/migrations", target: version, allow_missing_migration_files: true)
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

  desc "Dump DB schema to db/schema.rb"
  task :schema do
    `sequel -d #{db_path} > ./db/schema.rb`
  end

  desc "Dump DB structure to db/structure.sql"
  task :structure do
    `pg_dump --no-privileges --no-owner --schema-only #{db_path} > ./db/structure.sql`
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

  def db_path
    return ENV['DATABASE_URL'] if ENV['DATABASE_URL']

    yaml = YAML.load_file(File.join('config', 'database.yml'))
    yaml[ENV['RACK_ENV'] || 'development']
  end

  def db_name
    db_path.split('/')[-1]
  end
end

