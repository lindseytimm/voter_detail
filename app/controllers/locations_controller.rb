class LocationsController < ApplicationController

  def index

  end


  def voting_info
    @street_number = ""
    @pre_direction = ""
    @street_name = ""
    @city = ""
    @zip = ""
		
		if (!params[:street_number].nil?)
			@street_number = params[:street_number]
		end
		
		if (!params[:pre_direction].nil?)
			@pre_direction = params[:pre_direction]
		end
		
		if (!params[:street_name].nil?)
			@street_name = params[:street_name]
		end
		
		if (!params[:city].nil?)
			@city = params[:city]
		end
		
		if (!params[:zip].nil?)
			@zip = params[:zip]
		end

    @addr_count = SangamonWeb.address_count(@street_number, @pre_direction, @street_name, @city, @zip).first
    
    if @addr_count.district_group_count == 0 then
      @results_code = 0
      @results = ""
    elsif @addr_count.district_group_count == 1 then
      @results_code = 1
      @results = SangamonWeb.results_1(@street_number, @pre_direction, @street_name, @city, @zip)
      @result_districts = SangamonWeb.result_districts(@street_number, @pre_direction, @street_name, @city, @zip)
    else
      if @addr_count.street_count == 1 then
        @results_code = 20
        @results = ""
      else
        @results_code = 16
        @results = SangamonWeb.results_16(@street_number, @pre_direction, @street_name, @city, @zip)
      end  
    end

    respond_to do |format|
      format.xml
    end

  end


end
