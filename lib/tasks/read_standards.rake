require 'csv'

namespace :standards do

    desc 'Import standards data from file'
    task :import => :environment do
        CSV.foreach(ENV['filepath'], {:headers => true, :header_converters => :symbol}) do |row|
            standard = Standard.find_by(ext_id: row[:ext_id])
            if standard.nil?
                standard = Standard.new
                standard.ext_id = row[:ext_id]
            end
            standard.code = row[:code]
            standard.description = row[:description]
            standard.save
        end
    end
end
