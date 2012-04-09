module PM

# A ListContainer responds to messages that manipulate the cursors for one
# or more List objects.
module ListContainer

  def method_missing(sym, *args)
    case sym.to_s
    when /^curr_(\w+)=$/
      name = $1
      ivar_sym = "@#{pluralize(name)}".to_sym
      raise "no such ivar #{ivar_sym} in #{self.class}" unless instance_variable_defined?(ivar_sym)
      instance_variable_get(ivar_sym).send(:curr=, args[0])
    when /^(first|next|prev|curr|last)_(\w+)(\?)?$/
      method, ivar, qmark = $1, $2, $3
      ivar_sym = "@#{pluralize(ivar)}".to_sym
      raise "no such ivar #{ivar_sym} in #{self.class}" unless instance_variable_defined?(ivar_sym)
      instance_variable_get(ivar_sym).send("#{method}#{qmark}".to_sym)
    else
      super
    end
  end

  def pluralize(str)
    case str
    when /s$/, /ch$/
      "#{str}es"
    when /y$/
      "#{str[0..-2]}ies}"
    else
      "#{str}s"
    end
  end

end
end
