class EventsController < ApplicationController
  def index
    require 'net/http'
    require 'rexml/document'
    require "builder"

    #GET events from FCT
		 news_url = "http://www.fct.unl.pt/noticias/rss.xml"
     news_result = Net::HTTP.get(URI(news_url))

     begin
       news = REXML::Document.new news_result
     rescue REXML::ParseException
       puts "An error has occurred - Invalid XML"
     end


    destaques_url ="http://www.fct.unl.pt/rss.xml"
    destaques_result = Net::HTTP.get(URI(destaques_url))

     begin
       destaques = REXML::Document.new destaques_result
     rescue REXML::ParseException
       puts "An error has occurred - Invalid XML"
     end

    xml_result = ""
    xml = Builder::XmlMarkup.new(:target => xml_result, :indent => 2)
       xml.list("title" => "FCT Events") do |list|

          news.elements.each("rss/channel/item") do |node|

            node.elements.each("title") do |child|
               @news_title = child.text
            end

            node.elements.each("pubDate") do |child|
              @news_date = child.text
            end
            node.elements.each("guid") do |child|
              my_array = child.text.split(" ")
              @news_id = "news-#{my_array[0]}"
            end
            list.item("title" => @news_title, "href"=> "#{SERVICE_IP}#{@news_id}") do |item|
              item.text(@news_date,"label" => "Date")
            end
          end

         destaques.elements.each("rss/channel/item") do |node|

            node.elements.each("title") do |child|
              @destaques_title = child.text
            end

            node.elements.each("pubDate") do |child|
              @destaques_date = child.text
            end

            node.elements.each("guid") do |child|
              my_array = child.text.split(" ")
              @destaques_id = "destaques-#{my_array[0]}"
            end

            list.item("title" => @destaques_title, "href"=> "#{SERVICE_IP}#{@destaques_id}") do |item|
              item.text(@destaques_date,"label" => "Date")
            end
         end

       end

    respond_to {|format| format.xml {render :xml => xml_result}}
  end

  def show
    require "nokogiri"
    require "open-uri"
    require 'net/http'
    require 'rexml/document'
    require "builder"

    id = params[:id]

    my_array = id.split("-")
    if(my_array[0] == "news")

     news_url = "http://www.fct.unl.pt/noticias/rss.xml"
     news_result = Net::HTTP.get(URI(news_url))

     begin
       news = REXML::Document.new news_result
     rescue REXML::ParseException
       puts "An error has occurred - Invalid XML"
     end


    news.elements.each("rss/channel/item") do |node|
      node.elements.each("guid") do |id|
        array = id.text.split(" ")
        if(array[0] == my_array[1])
          node.elements.each("link") do |child|
            @news_link = child.text
          end
        end
      end
    end

    doc = Nokogiri::HTML(open(@news_link), nil, "utf-8")

    doc.xpath('//h1[@class="page-titles"]').each do |title|
      @news_title = title.content
    end
    doc.xpath('//div[@class="content clear-block"]').each do |descDiv|
      descDiv.xpath('//p').each do |description|
        @news_description = description.content
      end
    end

    xml_result = ""

    xml = Builder::XmlMarkup.new(:target => xml_result, :indent => 2)
       #xml.instruct! :xml, :version => "1.1", :encoding => "utf-8"
       xml.record("title" => @news_title) do |record|
        record.group("title" => "Description") do |group|
          group.item(@news_description)
        end
       end
     respond_to do |format|
        format.xml {render :xml => xml_result}
     end

    elsif(my_array[0]= "destaques")
          destaques_url = "http://www.fct.unl.pt/rss.xml"
     destaques_result = Net::HTTP.get(URI(destaques_url))

     begin
       destaques = REXML::Document.new destaques_result
     rescue REXML::ParseException
       puts "An error has occurred - Invalid XML"
     end


    destaques.elements.each("rss/channel/item") do |node|
      node.elements.each("guid") do |id|
        array = id.text.split(" ")
        if(array[0] == my_array[1])
          node.elements.each("link") do |child|
            @destaques_link = child.text
          end
        end
      end
    end

    doc = Nokogiri::HTML(open(@destaques_link), nil, "utf-8")

    doc.xpath('//h1[@class="page-titles"]').each do |title|
      @destaques_title = title.content
    end
    doc.xpath('//div[@class="content clear-block"]').each do |descDiv|
      descDiv.xpath('//p').each do |description|
        @destaques_description = description.content
      end
    end

    xml_result = ""

    xml = Builder::XmlMarkup.new(:target => xml_result, :indent => 2)
       #xml.instruct! :xml, :version => "1.1", :encoding => "utf-8"
       xml.record("title" => @destaques_title) do |record|
        record.group("title" => "Description") do |group|
          group.item(@destaques_description)
        end
       end
     respond_to do |format|
        format.xml {render :xml => xml_result}
     end
    end

  end

  def metainfo
    file = File.open("metainfo.xml", "r")
    meta = ""
    i = 0
    file.each_line do |line|
      if(i == 0)
        meta+="<service name=\"FCT Events\" url =\"#{SERVICE_IP}\">"
      else
        meta += line
      end
      i+=1
    end
    file.close

    respond_to { |format| format.xml { render :xml => meta } }
  end
end

