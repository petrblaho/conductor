#
#   Copyright 2012 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

# Before filter for controllers that handle REST API requests. Conductor uses
# linking to nested resources like
# <credential_definitions><credential_definition>...</credential_definition><credential_definition>...</credential_definition></credential_definitions>
# (resulting in :credential_definitions => { :credential_definition => [ { ... }, { ... } ] in request params hash)
# but ActiveRecord expects nested resources attributes like
# :credential_definitions_attributes => [ { :credential_definition => ... }, { :credential_definition => ... } ]
#
# This before filter operates on request params hash to rewrite it from our
# format to ActiveRecord-accept_nested_attributes_for-friendly format (for nested collections).
#
# The constructor of the filter accepts specification of what should be
# transformed. E.g.:
#
#  before_filter NestedResourcesAttributesFilter.new({ :provider_type => :credential_definitions }),
#                :only => [:create, :update]
#
# would transform { :provider_type => { :credential_definitions => { :credential_definition => [ { ... }, { ... } ] } } }
# into            { :provider_type => { :credential_definitions_attributes => [ { ... }, { ... } ]}}
#
# See the specs in spec/util/nested_resources_attributes_filter_spec.rb for more examples.
#
class NestedResourcesAttributesFilter
  def initialize(nested_resources)
    @nested_resources = nested_resources
  end

  def before(controller)
    return unless controller.request.format == :xml

    transform_nested_resources_recursively(controller.params, @nested_resources)
  end


  private

  def transform_nested_resources_recursively(subparams, subkeys)
    return if subparams == nil

    case subkeys
    when Symbol # then transform the link (last level of recursion)
      return if subparams[subkeys] == nil

      value = attributes = subparams.delete(subkeys)
      value = [ attributes.delete(subkeys.to_s.singularize.to_sym) ].flatten if attributes.is_a?(Hash)
      subparams[:"#{subkeys}_attributes"] = value
    when Array # then process each item
      subkeys.each do |item|
        transform_nested_resources_recursively(subparams, item)
      end
    when Hash # then descend into each entry
      subkeys.each_key do |key|
        transform_nested_resources_recursively(subparams[key], subkeys[key])
      end
    end
  end
end
