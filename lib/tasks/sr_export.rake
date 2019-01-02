require 'httparty'
require 'uri'

def char_from_answer_index(index)
    (index+65).chr
end

def correct_answers(question)
    correct_answers = []
    if question[:answers]
        question[:answers].each_with_index { |answer, index|
            if answer[:weight] == 100
                correct_answers.push(char_from_answer_index(index))
            end
        }
    end
    correct_answers.join
end

def compile_submission_answers(submission, quiz)
    quiz.root_entries.each_with_index.map { |question, index|
        answer = ''
        question_answer = submission[:submission_data].find {|answer| answer[:question_id] == question[:id]}
        if question_answer
            if question[:question_type] == 'multiple_choice_question'
                answer = char_from_answer_index(question[:answers].index {|answer| answer[:id] == question_answer[:answer_id] })
            elsif question[:question_type] == 'multiple_answers_question'
                answer = question[:answers].each_with_index.map { |answer, index|
                    if question_answer && question_answer[('answer_' + answer[:id].to_s).to_sym] == "1"
                        char_from_answer_index(index)
                    else
                        ''
                    end
                }.join
            end
        end
        {
            :question_number => index + 1,
            :answer => answer,
            :points => question_answer ? question_answer[:points] : 0
        }
    }
end

def compile_student_work(submissions, quiz)
    student_work = []
    submissions.each { |submission|
        if submission.user && submission.finished_at
            student_sis_pseudonym = SisPseudonym.for(submission.user, LoadAccount.default_domain_root_account, type: :implicit, require_sis: false)

            student_work.push({
                :student => {
                    :student_id => student_sis_pseudonym.ext_id
                },
                :score_override => submission.kept_score,
                :submission_date => submission.finished_at.strftime('%Y-%m-%d'),
                :answers => compile_submission_answers(submission, quiz)
            })
        end
    }

    student_work
end

def quiz_sr_api_data(quiz)
    teacher = quiz.course.teachers.first
    sis_pseudonym = SisPseudonym.for(teacher, LoadAccount.default_domain_root_account, type: :implicit, require_sis: false)
    sr_id = sis_pseudonym.ext_id
    school_id = sis_pseudonym.school_id

    puts quiz.inspect
    puts (quiz.unlock_at or quiz.published_at)

    {
        :assessment_definition => {
            :external_assessment_id => 'CANVAS_' + quiz.id.to_s,
            :date => (quiz.unlock_at or quiz.published_at).strftime('%Y-%m-%d'),
            :name => quiz.quiz_title,
            :school => {
                :school_id => school_id
            },
            :students_active => 1,
            :course => {
                :course_id => quiz.course.sis_source_id
            },
            :section_periods => quiz.course.course_sections.map { |section| section.sis_source_id },
            :assessment_type => {
                :assessment_type_id => 8 # TODO: Should everything be a weekly quiz?
            },
            :staff_member => {
                :staff_member_id => sr_id
            },
            :questions => quiz.root_entries.map { |question|
                {
                    :question_number => question[:position],
                    :question_name => question[:name],
                    :correct_answers => correct_answers(question),
                    :point_value => question[:points_possible],
                    :objective => {
                        :objective_id => question[:standard_id] || "" # todo: load the standard to get the ext_id
                    }
                }
            }
        },
        :assessment_answers => [
            compile_student_work(quiz.quiz_submissions, quiz)
        ]
    }
end

namespace :sr do

    desc 'Export assessment data to SchoolRunner'
    task :export => :environment do
        quizzes = Quizzes::Quiz.where.not(published_at: nil)
                               .where.not(workflow_state: 'deleted')

        for quiz in quizzes do
            puts '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
            puts quiz_sr_api_data(quiz).inspect
            puts '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'

            # response = HTTParty.post("https://republic.sandbox.schoolrunner.org/api/v1/assessments/import",
            #                         :body => {
            #                             :assessment_data => data.to_json
            #                         },
            #                         :basic_auth => {:username=>"984fc9c37dee56a4ee2e5f74ae891ec62423926b", :password=>""})

            # puts response.code.to_s
            # puts response.headers.to_s
            # puts response.body.to_s
        end

        puts "Export complete"
    end
end
