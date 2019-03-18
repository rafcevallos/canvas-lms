require 'httparty'
require 'uri'
require 'json'

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
        answered_question = submission[:quiz_data][index]
        if question_answer && question_answer.key?(:answer_id)
            if question[:question_type] == 'multiple_choice_question'
                answer = char_from_answer_index(answered_question[:answers].index {|answer| answer[:id] == question_answer[:answer_id] })
            elsif question[:question_type] == 'multiple_answers_question'
                answer = answered_question[:answers].each_with_index.map { |answer, index|
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
                    :external_id => student_sis_pseudonym.sis_user_id
                },
                :score_override => '',
                :submission_date => submission.finished_at.strftime('%Y-%m-%d'),
                :answers => compile_submission_answers(submission, quiz)
            })
        end
    }

    student_work
end

def quiz_sr_api_data(quiz)
    # puts('QUIZ', quiz.quiz_data.each.reject { |type|
    #     type[:question_type] == 'text_only_question'
    # })
    teacher = quiz.course.teachers.first
    sis_pseudonym = SisPseudonym.for(teacher, LoadAccount.default_domain_root_account, type: :implicit, require_sis: false)
    sr_id = sis_pseudonym.ext_id
    school_id = sis_pseudonym.school_id
    section_period_ids = quiz.course.course_sections.each.reject { |section|
        section[:section_period_ids].blank?
    }.map { |section|
        section[:section_period_ids]
    }.join(',').split(',').map { |section_period|
        section_period.to_i
    }
    used_question_types = quiz.root_entries.reject { |q|
        q[:question_type] == 'text_only_question'
    }
    puts('USED QUESTION TYPE', used_question_types)
    # puts('SECTION PERIOD IDs: ', section_period_ids.to_s)
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
                :course_id => quiz.course.sr_id
            },
            :section_periods => section_period_ids,
            :assessment_type => {
                :assessment_type_id => 8 # TODO: eventually everything won't be a weekly quiz
            },
            :staff_member => {
                :staff_member_id => sr_id
            },
            :questions => quiz.root_entries.reject { |question|
                question[:question_type] == 'text_only_question'
            }.map { |question|
                standard = Standard.find_by(standard_group_id: question[:standard_group_id].to_i, school_id: school_id)
                standard_id = standard.nil? ? "" : standard[:ext_id]
                {
                    :question_number => question[:position],
                    :question_name => question[:question_name],
                    :question_type => question[:question_type],
                    :correct_answers => correct_answers(question),
                    :point_value => question[:points_possible],
                    :comment => "",
                    :objective => {
                        :objective_id => standard_id.to_s
                    }
                }
            }
        },
        :assessment_answers => compile_student_work(quiz.quiz_submissions, quiz)
    }
end

namespace :sr do

    desc 'Export assessment data to SchoolRunner'
    task :export => :environment do
        assessment_groups = {}
        # quizzes = Quizzes::Quiz.where.not(published_at: nil)
        #                        .where.not(workflow_state: 'deleted')
        quizzes = Quizzes::Quiz.find([27, 28])
        for quiz in quizzes do
            quiz_data = quiz_sr_api_data(quiz)

            puts('QUIZ DATA: ', quiz_data.inspect)

            # response = HTTParty.post(ENV['SR_URL'] + "/api/v1/assessments/import",
            response = HTTParty.post("https://republic.sandbox.schoolrunner.org" + "/api/v1/assessments/import",
                                    :body => {
                                        :assessment_data => quiz_data.to_json
                                    },
                                    :basic_auth => {:username=>"984fc9c37dee56a4ee2e5f74ae891ec62423926b", :password=>""})

            json_response = JSON.parse(response.body)
            if json_response['success']
                assessment_id = json_response['results']['import_0']['assessment_definition']['assessment_id']
                quiz[:sr_id] = assessment_id
                quiz.save

                unless assessment_groups.key?(quiz.quiz_title)
                    assessment_groups[quiz.quiz_title] = []
                end
                assessment_groups[quiz.quiz_title].push assessment_id.to_i
            end
        end

        # path_response = HTTParty.post(ENV['PATH_URL'] + "/dat-assessments/assessment-groups/configure",
        #                               :body => {
        #                                   'groups' => assessment_groups
        #                               }.to_json,
        #                               :headers => { 'Content-Type' => 'application/json' })

        puts "Export complete"
    end
end