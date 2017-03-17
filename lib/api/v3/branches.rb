require 'mime/types'

module API
  module V3
    class Branches < Grape::API
      before { authenticate! }
      before { authorize! :download_code, user_project }

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects do
        desc 'Get a project repository branches' do
          success ::API::Entities::RepoBranch
        end
        get ":id/repository/branches" do
          branches = user_project.repository.branches.sort_by(&:name)

          present branches, with: ::API::Entities::RepoBranch, project: user_project
        end

        desc 'Delete a branch'
        params do
          requires :branch, type: String, desc: 'The name of the branch'
        end
        delete ":id/repository/branches/:branch", requirements: { branch: /.+/ } do
          authorize_push_project

          result = DeleteBranchService.new(user_project, current_user).
                   execute(params[:branch])

          if result[:status] == :success
            status(200)
            {
              branch_name: params[:branch]
            }
          else
            render_api_error!(result[:message], result[:return_code])
          end
        end

        desc 'Delete all merged branches'
        delete ":id/repository/merged_branches" do
          DeleteMergedBranchesService.new(user_project, current_user).async_execute

          status(200)
        end

        desc 'Create branch' do
          success ::API::Entities::RepoBranch
        end
        params do
          requires :branch_name, type: String, desc: 'The name of the branch'
          requires :ref, type: String, desc: 'Create branch from commit sha or existing branch'
        end
        post ":id/repository/branches" do
          authorize_push_project
          result = CreateBranchService.new(user_project, current_user).
            execute(params[:branch_name], params[:ref])

          if result[:status] == :success
            present result[:branch],
              with: ::API::Entities::RepoBranch,
              project: user_project
          else
            render_api_error!(result[:message], 400)
          end
        end
      end
    end
  end
end
