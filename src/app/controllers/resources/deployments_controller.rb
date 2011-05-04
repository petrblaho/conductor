class Resources::DeploymentsController < ApplicationController
  before_filter :require_user
  before_filter :load_deployments, :only => [:index, :show]

  def index
  end

  def launch_new
    @launchable_deployables = []
    Deployable.all.each do |deployable|
      @launchable_deployables << deployable if deployable.launchable?
    end
  end

  def new
    require_privilege(Privilege::CREATE, Deployment)
    @deployment = Deployment.new(:deployable_id => params[:deployable_id])
    if @deployment.deployable.assemblies.empty?
      flash[:warning] = "Deployable must have at least one assembly"
      redirect_to resources_deployments_path
    else
      init_new_deployment_attrs
    end
  end

  def create
    require_privilege(Privilege::CREATE, Deployment)
    @deployment = Deployment.new(params[:deployment])
    @deployment.owner = current_user
    if @deployment.save
      flash[:notice] = "Deployment launched"
      errors = @deployment.launch(params[:hw_profiles], current_user)
      unless errors.empty?
        flash[:error] = {
          :summary  => "Failed to launch following assemblies:",
          :failures => errors
        }
      end
      redirect_to resources_deployment_path(@deployment)
    else
      flash.now[:warning] = "Deployment launch failed"
      init_new_deployment_attrs
      render :new
    end
  end

  def show
    @deployment = Deployment.find(params[:id])
    require_privilege(Privilege::VIEW, @deployment)
    init_new_deployment_attrs
    @tab_captions = ['Properties', 'Instances', 'Provider Services', 'Required Services', 'History', 'Permissions']
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]
    respond_to do |format|
      format.js do
        if @url_params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @details_tab and return
      end
      format.html { render :action => 'show'}
    end
  end

  def multi_stop
    notices = ""
    errors = ""
    Deployment.find(params[:deployments_selected]).each do |deployment|
      deployment.instances.each do |instance|
        begin
          require_privilege(Privilege::USE,instance)
          unless instance.valid_action?('stop')
            raise ActionError.new("stop is an invalid action.")
          end

          # not sure if task is used as everything goes through condor
          #permissons check here
          @task = instance.queue_action(@current_user, 'stop')
          unless @task
            raise ActionError.new("stop cannot be performed on this instance.")
          end
          condormatic_instance_stop(@task)
          notices << "Deployment: #{instance.deployment.name}, Instance:  #{instance.name}: stop action was successfully queued.<br/>"
        rescue Exception => err
          errors << "Deployment: #{instance.deployment.name}, Instance: #{instance.name}: " + err + "<br/>"
        end
      end
    end
    flash[:notice] = notices unless notices.blank?
    flash[:error] = errors unless errors.blank?
    redirect_to resources_deployments_path
  end

  private
  def load_deployments
    @url_params = params
    @deployments = Deployment.paginate(:all,
      :page => params[:page] || 1,
      :order => (params[:order_field] || 'name')  +' '+ (params[:order_dir] || 'asc')
    )
    @header = [
      { :name => "", :sort_attr => :name },
      { :name => "Deployment name", :sort_attr => :name },
      { :name => "Deployable", :sortable => false },
      { :name => "Owner", :sort_attr => "owner.login"},
      { :name => "Running Since", :sort_attr => :running_since },
      { :name => "Pool", :sort_attr => "pool.name" }
    ]
    @pools = Pool.list_for_user(current_user, Privilege::CREATE, :target_type => Deployment)
    @deployments = Deployment.all(:include => :owner,
                              :conditions => {:pool_id => @pools},
                              :order => (params[:order_field] || 'name') +' '+ (params[:order_dir] || 'asc')
    )
  end

  def init_new_deployment_attrs
    @pools = Pool.list_for_user(@current_user, Privilege::CREATE, :target_type => Deployment)
    @realms = FrontendRealm.all
    @hardware_profiles = HardwareProfile.all(
      :include => :architecture,
      :conditions => {:provider_id => nil}
    )
  end
end
