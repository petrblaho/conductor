#
#   Copyright 2011 Red Hat, Inc.
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

class ProviderTypesController < ApplicationController
  before_filter :require_user
  before_filter NestedResourcesAttributesFilter.new(:provider_type => :credential_definitions), :only => :create

  def index
    @provider_types = ProviderType.all
    respond_to do |format|
      format.xml { render :partial => 'list.xml' }
    end
  end

  def show
    @provider_type = ProviderType.find(params[:id])
    respond_to do |format|
      format.xml
    end
  end

  def destroy
    @provider_type = ProviderType.find(params[:id])
    require_privilege(Privilege::MODIFY, @provider)
    respond_to do |format|
      format.xml do
        if @provider_type.safe_destroy
          render :nothing => true, :status => :no_content
        else
          raise Aeolus::Conductor::API::Error.new(500, @provider_type.errors.full_messages.join(', '))
        end
      end
    end
  end

  def create
    @provider_type = ProviderType.new(params[:provider_type])

    # links each new Credential Definition with new Provider type
    # so validations do not fail
    # accept_nested_attributes_for do not do this - why?
    @provider_type.credential_definitions.each do |cd|
      cd.provider_type = @provider_type
    end

    if @provider_type.save
      respond_to do |format|
        format.xml { render :show, :status => :created }
      end
    else
      respond_to do |format|
        format.xml  { render :template => 'api/validation_error',
                             :status => :unprocessable_entity,
                             :locals => { :errors => @provider_type.errors }}
        #format.xml { render :text => "#{request.inspect}\n\n#{params[:provider_type].inspect}\n\n#{@provider_type.errors.inspect}" }
      end
    end
  end

end
