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

require 'spec_helper'

describe NestedResourcesAttributesFilter do

  describe "#transform_nested_resources" do

    let(:array_of_resources) do
      [
        { :name => 'cd1' },
        { :name => 'cd2' },
      ]
    end

    before do
      @controller = stub({
        :request => stub({
          :format => :xml
        })
      })
      @controller.stub(:params).and_return(params)
    end

    context "successful transformation" do

      before do
        NestedResourcesAttributesFilter.new(nested_resources).before(@controller)
      end

      context "for a simple nested resources collection" do
        let(:params) do
          {
            :provider_type =>
            {
              :credential_definitions =>
              {
                :credential_definition => array_of_resources
              },
              :do_not_transform_key => :whatever,
            }
          }
        end
        let(:nested_resources) { { :provider_type => :credential_definitions } }

        it "transforms the link" do
          params[:provider_type][:credential_definitions].should == nil
          params[:provider_type][:credential_definitions_attributes].should == array_of_resources
          params[:provider_type][:do_not_transform_key].should == :whatever
        end
      end

      context "for multiple nested resources collections" do
        let(:params) do
          {
            :provider_type => {
              :credential_definitions => { :credential_definition => array_of_resources },
              :some_resources => { :some_resource => 456 },
              :do_not_transform_key => :whatever,
            }
          }
        end
        let(:nested_resources) { { :provider_type => [:credential_definitions, :some_resources] } }

        it "transforms the links" do
          params[:provider_type][:credential_definitions].should == nil
          params[:provider_type][:credential_definitions_attributes].should == array_of_resources
          params[:provider_type][:some_resources].should == nil
          params[:provider_type][:some_resources_attributes].should == [ 456 ]
          params[:provider_type][:do_not_transform_key].should == :whatever
        end
      end

      context "for combined single- and double-nested resources" do
        let(:params) do
          { :catalog => {
              :pools => { :pool => array_of_resources },
              :nesting => {
                :first_resources => { :first_resource => 123 },
                :second_resources => { :second_resource => 456 },
                :third_not_transformed => :whatever,
              }
            }
          }
        end
        let(:nested_resources) do
          {
            :catalog => [
              :pools,
              { :nesting => [:first_resources, :second_resources] }
          ]
          }
        end

        it "transforms the links" do
          params[:catalog][:pools].should == nil
          params[:catalog][:pools_attributes].should == array_of_resources
          params[:catalog][:nesting][:first_resources].should == nil
          params[:catalog][:nesting][:first_resources_attributes].should == [ 123 ]
          params[:catalog][:nesting][:second_resources].should == nil
          params[:catalog][:nesting][:second_resources_attributes].should == [ 456 ]
          params[:catalog][:nesting][:third_not_transformed].should == :whatever
        end
      end

    end

    #context "when missing 'id' attribute in the link" do
    #  let(:params) do
    #    {
    #      :catalog => {}
    #    }
    #  end
    #  let(:nested_resources) { :catalog }

    #  it "does not transform anything" do
    #    params[:catalog].should == {}
    #    params[:catalog_id].should == nil
    #  end
    #end

    #context "when missing the whole link" do
    #  let(:params) { {} }
    #  let(:nested_resources) { :catalog }

    #  it "does not transform anything" do
    #    params[:catalog].should == nil
    #    params[:catalog_id].should == nil
    #  end
    #end

    #context "when not XML request" do
    #  let(:params) { {} }

    #  before do
    #    @controller.stub_chain(:request, :format).and_return(:html)
    #  end

    #  it "does not touch params" do
    #    @controller.should_not_receive(:params)
    #    NestedResourcesAttributesFilter.new(:something).before(@controller)
    #  end
    #end

  end

end
