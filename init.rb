require 'asbestos'
ActionView::Template.register_template_handler(:asbestos, Asbestos::TemplateHandler)
ActionController::Base.__send__(:include, Asbestos::ControllerMethods)