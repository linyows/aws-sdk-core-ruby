$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'aws-sdk-resources', 'lib')))

# KNOWN ISSUES
#
# - Changed Resource::Base#data, #client and #attributes from
#   attr_reader to methods so I could override them in the client
#   with the appropriate return values
#
#   - This appears to be caused by embed-mixins
#   - might be fixed if I could document the attr_reader in the subclass 
#   - method appears twice when I leave it as attr_reader in subclass
#   - able to work around this by creating method object, and moving it
#     into the instance_attributes[:client] = { :read => m } and marking
#     parent attr_reader as @api private
#
# - Unable to access data attributes for resources that have no load method defined,
#   such as Bucket#creation_date unless the resource is constructed from an enumerator.
#   Bucket.new(name:'aws-sdk').creation_date raises a NotImplementedError
#
# - How to preserve ordering of grouped methods, such as "Identifiers" - these
#   have a logical ordering and they are being lexically ordered.
#
# TODOs
#
# - Document batch operations in the Resource class docstring
# - Document operation inputs, subtracting provided inputs
# - Document operation response structures for operations that return responses or data
# - Add "documentation" traits to resource definitions for each operation
# - Document resource constructors
# - Investigate adding @see tags to related operations
# - Enumerate resource operations should document they return a
#   Collection, not Enumerator
#

require 'aws-sdk-resources'

YARD::Parser::SourceParser.after_parse_list do
  ResourceDocPlugin.new.apply
end

class ResourceDocPlugin

  def apply
    Aws.service_added do |_, svc_module, files|

      Aws::Api::Docstrings.apply(svc_module::Client, files[:docs])

      namespace = YARD::Registry[svc_module.name]
      svc_module.constants.each do |const|
        klass = svc_module.const_get(const)
        if klass.ancestors.include?(Aws::Resource::Base)
          yard_class = document_resource_class(const, namespace, klass)
          if const == :Resource
            yard_class.docstring = service_docstring(const, yard_class, klass)
          end
        end
      end
    end
  end

  def service_docstring(name, yard_class, svc_class)
    api = svc_class.client_class.api
    product_name = api.metadata('serviceAbbreviation')
    product_name ||= api.metadata('serviceFullName')

    docstring = <<-DOCSTRING.strip
This class provides a resource oriented interface for #{product_name}.
To create a resource object:

    #{name.downcase} = #{svc_class.name}.new

You can supply a client object with custom configuration that will be
used for all resource operations.  If you do not pass `:client`,
a default client will be constructed.

    client = Aws::#{name}.new(region: 'us-west-2')
    #{name.downcase} = #{svc_class.name}.new(client: client)

# #{name} Resource Classes

#{svc_class.name} has the following resource classes:

#{svc_class.constants.sort.map { |const| "* {#{const}}" }.join("\n")}
    DOCSTRING
  end

  def document_resource_class(name, namespace, resource_class)
    yard_class = YARD::CodeObjects::ClassObject.new(namespace, name)
    yard_class.superclass = YARD::Registry['Aws::Resource::Base']
    document_client_getter(yard_class, resource_class)
    document_identifiers_hash(yard_class, resource_class)
    document_identifier_attributes(yard_class, resource_class)
    document_data_attribute_getters(yard_class, resource_class)
    document_operation_methods(yard_class, resource_class)
    yard_class
  end

  def document_client_getter(yard_class, resource_class)
    client_class = resource_class.client_class.name.split('::', 2).last
    m = YARD::CodeObjects::MethodObject.new(yard_class, :client)
    m.scope = :instance
    m.add_tag(YARD::Tags::Tag.new(:return, '', [client_class]))
    yard_class.instance_attributes[:client] = { :read => m }
  end

  def document_identifiers_hash(yard_class, resource_class)
    identifiers = resource_class.identifiers
    m = YARD::CodeObjects::MethodObject.new(yard_class, :identifiers)
    m.scope = :instance
    docstring = if identifiers.empty?
      "Returns an empty hash. This resource class is constructed without identifiers."
    else
      identifiers = identifiers.map { |i| "`:#{i}`" }.join(', ')
      "Returns a read-only hash with the following keys: #{identifiers}."
    end
    m.docstring = docstring
    m.add_tag(YARD::Tags::Tag.new(:return, nil, ['Hash']))
    yard_class.instance_attributes[:identifiers] = { :read => m }
  end

  def document_identifier_attributes(yard_class, resource_class)
    identifiers = resource_class.identifiers
    group = identifiers.count > 1 ? 'Identifiers' : 'Identifier'
    identifiers.each do |identifier_name|
      m = YARD::CodeObjects::MethodObject.new(yard_class, identifier_name)
      m.scope = :instance
      m.group = group
      m.docstring = ''
      m.add_tag(YARD::Tags::Tag.new(:return, nil, ['String']))
      yard_class.instance_attributes[identifier_name] = { :read => m }
    end
  end

  def document_data_attribute_getters(yard_class, resource_class)

    _, svc, resource_name = resource_class.name.split('::')

    return if resource_name == 'Resource'

    definition = File.read("aws-sdk-core/apis/#{svc}.resources.json")
    definition = MultiJson.load(definition)
    definition = definition['resources'][resource_name]
    if shape_name = definition['shape']

      shape = resource_class.client_class.api.shape_map.shape('shape' => shape_name)

      resource_class.data_attributes.each do |member_name|

        member_shape = shape.member(member_name)
        return_type = case member_shape
          when Seahorse::Model::Shapes::Blob then 'String<bytes>'
          when Seahorse::Model::Shapes::Byte then  'String<bytes>'
          when Seahorse::Model::Shapes::Boolean then 'Boolean'
          when Seahorse::Model::Shapes::Character then 'String'
          when Seahorse::Model::Shapes::Double then 'Float'
          when Seahorse::Model::Shapes::Float then 'Float'
          when Seahorse::Model::Shapes::Integer then 'Integer'
          when Seahorse::Model::Shapes::List then 'Array'
          when Seahorse::Model::Shapes::Long then 'Integer'
          when Seahorse::Model::Shapes::Map then 'Hash'
          when Seahorse::Model::Shapes::String then 'String'
          when Seahorse::Model::Shapes::Structure then 'Structure'
          when Seahorse::Model::Shapes::Timestamp then 'Time'
          else raise 'unhandled type'
        end

        m = YARD::CodeObjects::MethodObject.new(yard_class, member_name)
        m.scope = :instance
        m.group = 'Data Attributes'
        m.docstring = "#{member_shape.documentation}\n@return [#{return_type}] #{member_shape.documentation}"
        #m.add_tag(YARD::Tags::Tag.new(:return, nil, [return_type]))
        yard_class.instance_attributes[member_name] = { :read => m }

      end
    end
  end

  def document_operation_methods(yard_class, resource_class)
    resource_class.operations.each do |name, operation|
      document_operation_method(yard_class, resource_class, name, operation)
    end
  end

  def document_operation_method(yard_class, resource_class, name, operation)
    type = operation.class.name.split('::').last
    documenter = Aws::Resource::Documenter.const_get(type + 'Documenter')
    documenter = documenter.new(yard_class, resource_class, name, operation)
    documenter.method_object
  end

end
