require 'csv'

namespace :standards do

    desc 'Import standards data from file'
    task :import => :environment do
        course_code = ENV['course']
        course = Course.find_by(course_code: course_code)

        if course.nil?
            puts 'Unable to find course "' + course_code + '"'
        else
            school_id = ENV['school']
            # Expects the standard csv to have the headers: ext_id, code, description, school_id
            CSV.foreach(ENV['filepath'], {:headers => true, :header_converters => :symbol}) do |row|
                standard = Standard.find_by(ext_id: row[:ext_id])
                if standard.nil?
                    standard = Standard.new
                    standard.ext_id = row[:ext_id]
                end
                standard.school_id = row[:school_id]
                standard.code = row[:code]
                standard.description = row[:description]
                standard.course = course

                group = StandardGroup.find_by(code: standard.code, description: standard.description)
                if group.nil?
                    group = StandardGroup.new
                    group.code = standard.code
                    group.description = standard.description
                    group.save
                end

                standard.standard_group = group
                standard.save
            end
        end
    end
end
