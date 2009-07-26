module Asbestos
  class TemplateHandler < ActionView::TemplateHandler
    include ActionView::TemplateHandlers::Compilable

    def compile(template, options = {})
      "_set_controller_content_type(Mime::JSON);" +
        "xml = ::Asbestos::Builder.new(#{options.inspect});" +
        # "self.output_buffer = xml.target!;" +
        template.source +
        ";xml.target!.to_json;"
    end
  end
  
  module ControllerMethods
    private
    def render_json_from_xml(options)
      template = @template.view_paths.find_template("#{controller_name}/#{action_name}", :xml)
      compiled_name = (template.method_name_without_locals + '_asbestos').to_sym
      
      if !ActionView::Base::CompiledTemplates.method_defined?(compiled_name)
        compiled_source = ::Asbestos::TemplateHandler.new.compile(template, options)
        
        ActionView::Base::CompiledTemplates.module_eval(<<-SRC, template.filename, 0)
          def #{compiled_name}
            old_output_buffer = output_buffer;#{compiled_source}
          ensure
            self.output_buffer = old_output_buffer
          end
        SRC
      end
      
      render :text => @template.with_template(template) {
        @template.send(:_evaluate_assigns_and_ivars)
        @template.send(compiled_name)
      }
    end
  end
  
  class Builder
    def initialize(options = {})
      @target = _new_hash
      @options = options
    end
    
    def target!
      @target
    end
    
    def instruct!(*args)
    end
    
    def tag!(sym, *args, &block)
      method_missing(sym.to_sym, *args, &block)
    end
    
    protected
    
    def method_missing(method, *args)
      method = method.to_s
      
      if method.ends_with?('!')
        super
      else
        value, attrs = _extract_value_and_attributes(args)
        
        if block_given?
          raise ArgumentError, "can't have mix values with a block" if value
          old_target = @target
          begin
            if _aggregates.include?(method)
              collection = old_target[method.pluralize] ||= []
              collection << (@target = _new_hash)
            elsif !_ignores.include?(method)
              @target = old_target[method] = _new_hash
            end
            attrs.each { |name, value| _write_pair(name, value) } if attrs
            yield
          ensure
            @target = old_target
          end
        else
          raise ArgumentError, "don't know what to do with attributes" if attrs
          _write_pair(method, value, _aggregates.include?(method))
        end
      end
    end
    
    private
    
    def _ignores
      @options[:ignore] ||= []
    end
    
    def _aggregates
      @options[:aggregate] ||= []
    end
    
    def _write_pair(key, value, aggregate = false)
      key = key.to_s.gsub('-', '_')
      if aggregate
        key = key.pluralize
        @target[key] ||= []
        @target[key] << value
      else
        @target[key] = value
      end
    end
    
    def _new_hash
      ActiveSupport::OrderedHash.new
    end
    
    def _extract_value_and_attributes(args)
      if args.first.kind_of?(Symbol)
        raise ArgumentError, "don't know how to do XML namespaces in JSON"
      end
      
      value = nil
      attrs = nil
      
      args.each do |arg|
        case arg
        when Hash
          attrs ||= {}
          attrs.update(arg)
        else
          if value
            value = value.to_s << arg.to_s
          else
            value = arg
          end
        end
      end
      
      [value, attrs]
    end
  end
end
