require "open3"

RSpec.describe Swimmy::Driver::RaskCliDriver do
  let(:driver) { Swimmy::Driver::RaskCliDriver }
  let(:success_status) { instance_double(Process::Status, success?: true) }
  let(:failure_status) { instance_double(Process::Status, success?: false) }

  before do
    ENV["RASK_CLI_DIR"] = "/path/to/rask/cli"
    driver.instance_variable_set(:@cli_dir, nil)
  end

  def expect_capture3(*expected_args)
    expect(Open3).to receive(:capture3)
      .with("/path/to/rask/cli/target/debug/rask-cli", *expected_args, chdir: "/path/to/rask/cli")
      .and_return(["dummy stdout", "", success_status])
  end

  describe ".task_create" do
    it "requires only title and assigner_name" do
      expect_capture3("task", "create", "--title", "buy milk", "--assigner-name", "john")

      driver.task_create(title: "buy milk", assigner_name: "john")
    end

    it "includes all optional flags when given" do
      expect_capture3(
        "task", "create",
        "--title", "buy milk", "--assigner-name", "john",
        "--state", "done",
        "--project-name", "shopping",
        "--due-at", "2036-2-6",
        "--description", "2% milk"
      )

      driver.task_create(
        title: "buy milk",
        assigner_name: "john",
        state: "done",
        project_name: "shopping",
        due_at: "2036-2-6",
        description: "2% milk"
      )
    end
  end

  describe ".task_list" do
    it "lists all tasks with no arguments" do
      expect_capture3("task", "list")

      driver.task_list
    end

    it "filters by username and requests json" do
      expect_capture3("task", "list", "--username", "john", "--json")

      driver.task_list("john", true)
    end
  end

  describe ".document_list" do
    it "lists all documents with no arguments" do
      expect_capture3("document", "list")

      driver.document_list
    end

    it "expands array filters into repeated values and requests json" do
      expect_capture3(
        "document", "list",
        "--content", "rust", "api",
        "--creator-name", "john",
        "--json"
      )

      driver.document_list(content: ["rust", "api"], creator_name: "john", is_json: true)
    end

    it "stringifies numeric filters" do
      expect_capture3("document", "list", "--id", "42", "--project-id", "7")

      driver.document_list(id: 42, project_id: 7)
    end
  end

  describe ".user_list" do
    it "requests json when asked" do
      expect_capture3("user", "list", "--json")

      driver.user_list(true)
    end
  end

  describe ".project_list" do
    it "requests json when asked" do
      expect_capture3("project", "list", "--json")

      driver.project_list(true)
    end
  end

  describe "error handling" do
    it "raises CommandFailedError when the CLI exits with failure" do
      allow(Open3).to receive(:capture3)
        .and_return(["", "boom", failure_status])

      expect { driver.task_list }.to raise_error(
        Swimmy::Driver::RaskCliDriver::CommandFailedError, /boom/
      )
    end

    it "raises when RASK_CLI_DIR is not set" do
      ENV.delete("RASK_CLI_DIR")

      expect { driver.task_list }.to raise_error(/RASK_CLI_DIR/)
    end
  end
end
