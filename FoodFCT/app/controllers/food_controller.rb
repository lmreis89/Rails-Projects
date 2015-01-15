class FoodController < ApplicationController
  before_filter :verify_date, :only => [:show, :search]

   def index
    require 'builder'
    require 'net/http'
    require 'rexml/document'

    tomorrow = "00:00"

    xml_result = ""
    xml = Builder::XmlMarkup.new(:target => xml_result, :indent => 2, :encoding => "UTF-8")
    xml.list("title" => "Food FCT ", :start =>"0" ,:end => "30", "ttl" => tomorrow) do |list|

      Restaurant.all.each do |rest|
        list.item("title" => rest.name, "href" => "#{SERVICE_IP}#{rest.id}")
      end
     respond_to { |format| format.xml { render :xml => xml_result } }
    end
    end

  def show
    require 'builder'
    require 'net/http'
    require 'rexml/document'

    restaurant = Restaurant.find(params[:id])

    xml_result = ""
    if(restaurant != nil)
      menus = restaurant.menus

      xml_result = ""
      xml = Builder::XmlMarkup.new(:target => xml_result, :indent => 2, :encoding => "UTF-8")
      xml.record("title" => restaurant.name) do |record|
        menus.all.each do |m|
          if(restaurant.web == 0)
          record.group("title" => m.meal) do |group|
            descript = m.description
            parsed =descript.split("/")
            parsed.each do |item|
              group.item(:title => item)
            end
          end
          else
            array = make_description(m.description)

            record.group("title" => "#{m.meal} - 2.35Eur" ) do |group|
              group.item("title"=>array[0])
              group.item("title"=>array[1])
              group.item("title"=>array[2])
            end
          end
        end
      end
      end
    respond_to { |format| format.xml { render :xml => xml_result } }
  end

  def rests
    Restaurant.create(:name => "Cantina FCT UNL", :url => "http://rdk.homeip.net/refeitas/feed.xml", :web => 1)

    teresa = Restaurant.create(:name => "Teresa Gato", :web => 0)
    teresa.menus << Menu.create(:meal => "Lunch" ,:description => "Lulas grelhadas - 3.50Euros/Bitoque - 2.50Euros")
    teresa.menus << Menu.create(:meal => "Dinner" ,:description => "Febras com champignon - 3.50Euros/Bitoque - 2.50Euros")

    tico = Restaurant.create(:name => "Tico", :web => 0)
    tico.menus << Menu.create(:meal => "Lunch" ,:description => "Esparguete bolonhesa - 3.00Eur/Bitoque - 3.00Eur")
    tico.menus <<  Menu.create(:meal => "Dinner" ,:description => "Lulas grelhadas - 3.50Eur/Bitoque - 2.50Eur")

    bar_di = Restaurant.create(:name => "Bar do DI" , :web => 0)
    bar_di.menus << Menu.create(:meal => "Lunch", :description => "Franguinho assado - 2.50Eur/ Hamburger cansado - 1.00Eur")
    bar_di.menus << Menu.create(:meal => "Dinner" , :description =>"Robalo Frito - 2.00Eur/Douradinhos de pescada - 2.00Eur ")

    fisica = Restaurant.create(:name => "Bar de Fisica", :web => 0)
    fisica.menus << Menu.create(:meal => "Lunch", :description => "Filetes de peixe - 2.50Eur/Hamburger grelhado - 2.00Eur/Bifes com cogumelos - 2.50Eur")
    fisica.menus << Menu.create(:meal => "Dinner" ,:description => "Febras com champignon - 3.50Euros/Bitoque - 2.50Euros")
  end

  def make_description(menu)
    array = []
    soup_index = "Sopa: ".size + 1
    diet_index = menu.index("Dieta") - 1
    plate_index = menu.index("Prato") - 1

    array[0] = menu[soup_index..diet_index]
    diet_index += "Dieta:".size + 2
    array[1] = menu[diet_index..plate_index]
    plate_index += "Prato:".size + 2
    array[2] = menu[plate_index..menu.size]
    return array
  end

  def metainfo
    file = File.open("metainfo.xml", "r")
    meta = ""
    i = 0
    file.each_line do |line|
      if(i == 0)
        meta+="<service name=\"Food FCT\" url =\"#{SERVICE_IP}\">"
      else
        meta += line
      end
      i+=1
    end
    file.close

    respond_to { |format| format.xml { render :xml => meta } }
  end

  def search
    require "builder"
    xml_result = ""
    keywords = params[:keywords].gsub('%', '\%').gsub('_', '\_').gsub(' ', '%')
    @start = params[:start].to_i
    @end = params[:end].to_i

    if(keywords != nil)
      if(@start <= @end)

        rests = Restaurant.joins('INNER JOIN menus ON menus.restaurant_id = restaurants.id')

        restaurants = rests.all(:conditions=> ['restaurants.name LIKE  ? OR menus.description LIKE  ?', ["%#{keywords}%"]*2].flatten, :select=>"DISTINCT restaurants.id, restaurants.name")

        xml_result = ""
        xml = Builder::XmlMarkup.new(:target => xml_result, :indent => 2, :encoding => "UTF-8")
        parse_next(restaurants, xml,@start,@end,keywords)
      else
        xml_result = ""
        xml = Builder::XmlMarkup.new(:target => xml_result, :indent => 2, :encoding => "UTF-8")
        xml.list("title" => "Resultados da pesquisa")
      end
    end
    respond_to { |format| format.xml { render :xml => xml_result } }
  end

  def parse_next(rests, xml,start,_end,keys)
   require 'builder'
   require 'set'

     @replaced_end = 0
     @next = 0
     if(rests.size != 0)
       if(_end >= (rests.size-1))
        @replaced_end = rests.size-1
       else
         @replaced_end = _end
         @next = _end + (_end - start) + 1
       end
       current_rests = rests[start..@replaced_end]
       if(@next > 0)
         xml.list("title" => "Resultados da pesquisa:", "start" => start, "end" => @replaced_end,
                  "next"=>"#{SERVICE_IP}search?keywords=#{keys}&start=#{@replaced_end+1}&end=#{@next}") do |list|
          build_searchlist(current_rests,list)
         end
       else
          xml.list("title" => "Resultados da pesquisa:", "start" => start, "end" => @replaced_end) do |list|
            build_searchlist(current_rests,list)
          end
       end
     end
  end

  def build_searchlist(rests,list)
    rests.each do |r|
      list.item(:title => r.name)
    end
  end

  def verify_date

    require 'builder'
    require 'net/http'
    require 'rexml/document'

     Restaurant.all.each do |restaurant|
       if(restaurant.web == 1)
       menus = Menu.find_by_restaurant_id(restaurant.id)

       if(menus == nil)
         if(menus != nil && (Time.now.to_date - menus.first.created_at.to_date).to_i <= 0)
          return
         end
        restaurant_result = Net::HTTP.get(URI(restaurant.url))

        begin
            rest = REXML::Document.new restaurant_result
        rescue REXML::ParseException
            puts "An error has occurred - Invalid XML"
        end
              count = 0
              rest.elements.each("feed") do |feed|
                  feed.elements.each("entry") do |node|
                    if(count == 0)                                                                                              ..
                      count+=1
                      node.elements.each("summary") do |child|
                        aux_string = child.text
                        aux_string2 = aux_string[7..aux_string.size]
                        array = aux_string2.split("Jantar")

                        restaurant.menus.destroy_all if (menus != nil)

                        lunch = "Lunch"
                        dinner = "Dinner"
                        restaurant.menus.create(:meal => lunch, :description => array[0])
                        restaurant.menus.create(:meal => dinner, :description => array[1])

                      end
                  end
                end
              end
          end
        end
      end
     end
end
