require 'spec_helper'

describe "GitLab Flavored Markdown", feature: true do
  let(:project) { create(:project) }
  let(:issue) { create(:issue, project: project) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:fred) do
    u = create(:user, name: "fred")
    project.team << [u, :master]
    u
  end

  before do
    allow_any_instance_of(Commit).to receive(:title).
      and_return("fix #{issue.to_reference}\n\nask #{fred.to_reference} for details")
  end

  let(:commit) { project.commit }

  before do
    login_as :user
    project.team << [@user, :developer]
  end

  describe "for commits" do
    it "renders title in commits#index" do
      visit namespace_project_commits_path(project.namespace, project, 'master', limit: 1)

      expect(page).to have_link(issue.to_reference)
    end

    it "renders title in commits#show" do
      visit namespace_project_commit_path(project.namespace, project, commit)

      expect(page).to have_link(issue.to_reference)
    end

    it "renders description in commits#show" do
      visit namespace_project_commit_path(project.namespace, project, commit)

      expect(page).to have_link(fred.to_reference)
    end

    it "renders title in repositories#branches" do
      visit namespace_project_branches_path(project.namespace, project)

      expect(page).to have_link(issue.to_reference)
    end
  end

  describe "for issues", feature: true, js: true do
    include WaitForVueResource

    before do
      @other_issue = create(:issue,
                            author: @user,
                            assignee: @user,
                            project: project)
      @issue = create(:issue,
                      author: @user,
                      assignee: @user,
                      project: project,
                      title: "fix #{@other_issue.to_reference}",
                      description: "ask #{fred.to_reference} for details")
    end

    it "renders subject in issues#index" do
      visit namespace_project_issues_path(project.namespace, project)

      expect(page).to have_link(@other_issue.to_reference)
    end

    it "renders subject in issues#show" do
      visit namespace_project_issue_path(project.namespace, project, @issue)

      expect(page).to have_link(@other_issue.to_reference)
    end

    it "renders details in issues#show" do
      visit namespace_project_issue_path(project.namespace, project, @issue)

      expect(page).to have_link(fred.to_reference)
    end

    it "renders updated subject once edited somewhere else in issues#show" do
      visit namespace_project_issue_path(project.namespace, project, @issue)
      @issue.update(title: "fix #{@other_issue.to_reference} and update")

      wait_for_vue_resource
      expect(page).to have_text("fix #{@other_issue.to_reference} and update")
    end
  end

  describe "for merge requests" do
    before do
      @merge_request = create(:merge_request, source_project: project, target_project: project, title: "fix #{issue.to_reference}")
    end

    it "renders title in merge_requests#index" do
      visit namespace_project_merge_requests_path(project.namespace, project)

      expect(page).to have_link(issue.to_reference)
    end

    it "renders title in merge_requests#show" do
      visit namespace_project_merge_request_path(project.namespace, project, @merge_request)

      expect(page).to have_link(issue.to_reference)
    end
  end

  describe "for milestones" do
    before do
      @milestone = create(:milestone,
                          project: project,
                          title: "fix #{issue.to_reference}",
                          description: "ask #{fred.to_reference} for details")
    end

    it "renders title in milestones#index" do
      visit namespace_project_milestones_path(project.namespace, project)

      expect(page).to have_link(issue.to_reference)
    end

    it "renders title in milestones#show" do
      visit namespace_project_milestone_path(project.namespace, project, @milestone)

      expect(page).to have_link(issue.to_reference)
    end

    it "renders description in milestones#show" do
      visit namespace_project_milestone_path(project.namespace, project, @milestone)

      expect(page).to have_link(fred.to_reference)
    end
  end
end
