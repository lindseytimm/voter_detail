xml.instruct!              # for the <?xml version="1.0" encoding="UTF-8"?> line
xml.results do               # xml.foo creates foo element
  xml.ResultCode @results_code      # you're inside a block so xml.bar will create <foo><bar/></foo> elements
  if @results_code == 1
    xml.result do
      x = @results.first
      xml.Precinct x.precinct_code.upcase
      xml.PrecinctName x.precinct_name.upcase
      xml.PollingPlace x.polling_place_name.upcase
      xml.PollingPlaceAddr1 x.addr1.upcase
      xml.BallotType x.ballot_type
      xml.Districts do
        @result_districts.each do |r|
          xml.District do
            xml.DistrictName r.district_name
            xml.DistrictType r.district_type
          end # xml.District do
        end # @results.each
      end # xml.Districts do
    end # xml.result do
  elsif @results_code == 16
    xml.streets do
      @results.each do |r|
        xml.street do
          xml.StreetName r.StreetName
          xml.StreetPre r.StreetPre
        end # xml.street do
      end # @results.each
    end # xml.streets do    
  end # if    
end # xml.results do