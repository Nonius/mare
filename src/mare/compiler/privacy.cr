##
# The purpose of the Privacy pass is to enforce the function privacy boundary.
# Functions whose identifier starts with an underscore are considered private,
# and can only be called from within the same library where they were defined.
#
# This pass does not mutate the Program topology.
# This pass does not mutate the AST.
# This pass may raise a compilation error.
# This pass keeps temporay state (on the stack) at the per-function level.
# This pass produces no output state.
#
class Mare::Compiler::Privacy
  def self.run(ctx, library)
    library.types.each do |t|
      t_link = t.make_link(library)
      ctx.infer[t_link].each_non_argumented_reified.each do |rt|
        t.functions.each do |f|
          f_link = f.make_link(t_link)
          ctx.infer[f_link].each_reified_func(rt).each do |rf|
            infer = ctx.infer[rf]

            check_reified_func(ctx, infer)
          end
        end
      end
    end
  end

  def self.check_reified_func(ctx, infer : Infer::ReifiedFuncAnalysis)
    infer.each_called_func.each do |pos, called_rt, called_func_link|
      # Only handle private calls (beginning with an underscore).
      return unless called_func_link.name.starts_with?("_")

      # If the call site's library is the same as the function's library,
      # then there is no privacy issue and we can move on without error.
      next if pos.source.library.path == called_func_link.type.library.path

      # Otherwise we raise it as an error.
      Error.at pos, "This function call breaks privacy boundaries", [{
        called_func_link.resolve(ctx).ident.pos,
        "this is a private function from another library"
      }]
    end
  end
end
