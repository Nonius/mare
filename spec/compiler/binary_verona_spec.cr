describe Mare::Compiler::BinaryVerona do
  it "creates a simple binary leveraging the Verona runtime" do
    source_dir = File.join(__DIR__, "../../examples/verona")

    Mare::Compiler.compile(source_dir, :binary_verona)

    no_test_failures =
      Mare::Compiler::BinaryVerona.run_last_compiled_program == 0

    no_test_failures.should eq true
  end
end
