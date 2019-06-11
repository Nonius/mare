module Mare::Compiler
  def self.execute(ctx, target : Symbol)
    case target
    when :copy         then ctx.run(Copy)
    when :macros       then ctx.run(Macros)
    when :sugar        then ctx.run(Sugar)
    when :lambda       then ctx.run(Lambda)
    when :classify     then ctx.run(Classify)
    when :refer        then ctx.run(ctx.refer)
    when :infer        then ctx.run(ctx.infer)
    when :completeness then ctx.run(Completeness)
    when :reach        then ctx.run(ctx.reach)
    when :paint        then ctx.run(ctx.paint)
    when :codegen      then ctx.run(ctx.code_gen)
    when :eval         then ctx.run(ctx.eval)
    when :binary       then ctx.run(Binary)
    else raise NotImplementedError.new(target)
    end
  end
  
  # TODO: Add invalidation, such that passes like :lambda can invalidate
  # passes like :classify and :refer instead of marking a dependency.
  def self.deps_of(target : Symbol) : Array(Symbol)
    case target
    when :copy then [] of Symbol
    when :macros then [] of Symbol
    when :sugar then [:macros]
    when :lambda then [:sugar, :macros]
    when :refer then [:lambda, :sugar, :macros]
    when :classify then [:refer, :lambda, :sugar, :macros]
    when :infer then [:classify, :refer, :lambda, :copy]
    when :completeness then [:infer, :lambda, :sugar, :macros, :copy]
    when :reach then [:infer]
    when :paint then [:reach]
    when :codegen then [:paint, :reach, :infer, :completeness, :classify]
    when :eval then [:codegen]
    when :binary then [:codegen]
    else raise NotImplementedError.new([:deps_of, target].inspect)
    end
  end
  
  def self.all_deps_of(target : Symbol) : Set(Symbol)
    deps_of(target).reduce(Set(Symbol).new) do |set, t|
      set.add(t)
      set.concat(all_deps_of(t))
    end
  end
  
  def self.satisfy(ctx, target : Symbol)
    all_deps_of_target = all_deps_of(target)
    all_deps = all_deps_of_target.map { |t| {t, all_deps_of(t)} }
    all_deps << {target, all_deps_of_target}
    all_deps.sort_by(&.last.size).map(&.first).each do |target|
      execute(ctx, target)
    end
    ctx
  end
  
  def self.get_library_sources(dirname)
    library = Source::Library.new(dirname)
    filenames = Dir.entries(dirname).select(&.ends_with?(".mare")).to_a
    
    raise "No '.mare' source files found in '#{dirname}'!" if filenames.empty?
    
    filenames.map do |name|
      Source.new(name, File.read(File.join(dirname, name)), library)
    end
  end
  
  def self.compile(dirname : String, target : Symbol = :eval)
    compile(get_library_sources(dirname), target)
  end
  
  def self.compile(sources : Array(Source), target : Symbol = :eval)
    compile(sources.map { |s| Parser.parse(s) }, target)
  end
  
  def self.compile(docs : Array(AST::Document), target : Symbol = :eval)
    raise "No source documents given!" if docs.empty?
    
    docs.concat(prelude_docs)
    
    ctx = Context.new
    docs.each { |doc| ctx.compile(doc) }
    
    satisfy(ctx, target)
  end
  
  @@prelude_docs : Array(AST::Document)?
  def self.prelude_docs
    # TODO: detect when the files have changed and invalidate the cache
    @@prelude_docs ||=
      begin
        get_library_sources(File.join(__DIR__, "../prelude"))
        .map { |s| Parser.parse(s) }
      end
    @@prelude_docs.not_nil!
  end
  
  def self.prelude_library
    prelude_docs.first.source.library
  end
end
