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
        :credential_definition => { :name => 'cd1' },
        :credential_definition => { :name => 'cd2' },
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
              :credential_definitions => array_of_resources
            }
          }
        end
        let(:nested_resources) { { :provider_type => :credential_definitions } }

        it "transforms the link" do
          params[:provider_type][:credential_definitions].should == nil
          params[:provider_type][:credential_definitions_attributes].should == array_of_resources
        end
      end

      context "for multiple nested resources collections" do
        let(:params) do
          {
            :provider_type => {
            :credential_definitions => array_of_resources,
            :some_resources => 456,
          }
          }
        end
        let(:nested_resources) { { :provider_type => [:credential_definitions, :some_resources] } }

        it "transforms the links" do
          params[:provider_type][:credential_definitions].should == nil
          params[:provider_type][:credential_definitions_attributes].should == array_of_resources
          params[:provider_type][:some_resources].should == nil
          params[:provider_type][:some_resources_attributes].should == 456
        end
      end

      context "for combined single- and double-nested resources" do
        let(:params) do
          { :catalog => {
              :pools => array_of_resources,
              :some_resources => {
                :double_nested_1 => 123,
                :double_nested_2 => 456,
              }
            }
          }
        end
        let(:nested_resources) do
          {
            :catalog => [
              :pools,
              { :some_resources => [:double_nested_1, :double_nested_2] }
          ]
          }
        end

        it "transforms the links" do
          params[:catalog][:pools].should == nil
          params[:catalog][:pools_attributes].should == array_of_resources
          params[:catalog][:some_resources][:double_nested_1].should == nil
          params[:catalog][:some_resources][:double_nested_1_attributes].should == 123
          params[:catalog][:some_resources][:double_nested_2].should == nil
          params[:catalog][:some_resources][:double_nested_2_attributes].should == 456
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
