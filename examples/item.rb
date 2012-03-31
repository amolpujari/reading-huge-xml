require 'awesome_print'
require '../reading_huge_xml.rb'

class Item

  def self.do_it
    clear_item
    
    HugeXML.read '../data/rss.xml', ['item', 'title', 'link', 'description'] do |element|

      case element[:name]
      when 'title'
        @@item[:title]       = element[:value]
      when 'link'
        @@item[:link]        = element[:value]
      when 'description'
        @@item[:description] = element[:value]
      when 'item'
        make_item
      end
      
    end
  end

  def self.make_item
    puts
    ap @@item

    clear_item
  end

  def self.clear_item
    @@item = {}
  end
end


Item.do_it


