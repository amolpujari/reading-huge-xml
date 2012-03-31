###
# Makes reading huge xml files very simple
# 
# ==== Examples
#
#   elements_lookup = ['record-root', 'record-children1', 'record-children2', 'record-children1-children1', 'record-children3' ]
#
#   HugeXML.read xml, elements_lookup do |element|
#
#     case element[:name]
#     when 'record-root'
#       do something with element[:value]
#       ....
#     when 'record-children1'
#       do something with element[:attributes]
#       ....
#     when 'record-children2'
#       ....
#     when 'record-children1-children1'
#       ....
#     when 'record-children3'
#       ....
#     end
#   end
#
# Uses Nokogiri::XML::Reader to read huge xml files.
#

require 'nokogiri'

module HugeXML

  ###
  #accepts
  #* <tt>:xml_path</tt> - xml file path
  #* <tt>:elements_lookup</tt> - array of elements to be find out and return/yeild, 
  #
  #  yields <tt>element => { :name => element_name_found, :value => its_value_if_any,
  #  :attributes => { :its_attributes => if_any}, :type =>  Nokogiri::XML::Reader element type }</tt>
  #
  def self.read xml_path, elements_lookup=nil
    reader = HugeXML::Reader.new
    reader.read xml_path

    while (element=reader.try_next elements_lookup)
      yield element, reader
    end
  end

  ###
  #  Reader class clubbed of all reading stuff
  # exposes read, try_next, try_next_with_value, and try_next_with_attributes
  #
  class Reader
    
    TYPE_END_OF_FILE = 0
    TYPE_OPENING_ELEMENT = 1

    # opens and reads given xml file
    def read xml_path
      @file = File.open(xml_path)
      reader = Nokogiri::XML::Reader(@file)
      @node = reader
      @node.read
    end

    # looks for any of the given elements, with making no more than specified attempts, if found return it
    # return first element found if elements=nil
    def try_next elements, attempts=nil
      @trys = attempts
      check_next elements
    end

    # looks for any of the given elements having some value/text/body, with making no more than specified attempts, if found return it
    def try_next_with_value elements, attempts=nil
      @trys = attempts
      check_next_with_value elements
      @trys = nil
    end
    
    # looks for any of the given elements having any attributes, with making no more than specified attempts, if found return it
    def try_next_with_attributes elements, attempts=nil
      @trys = attempts
      check_next_with_attributes elements
      @trys = nil
    end
    
    private

    def check_next_with_value elements
      @value = nil
      check_next elements while not @value
    end
    
    def check_next_with_attributes elements
      @attributes = nil
      check_next elements while not @attributes
    end
    
    def check_next elements
      elements = [elements].flatten if elements
      match = false

      while not match
        return unless @file
        
        if @trys
          @trys -=1
          return if @trys==0
        end

        next_element
        next unless @type==TYPE_OPENING_ELEMENT
        match = (elements==nil) || (elements.include? @name)
      end

      @trys = nil
      { :name => @name, :value => @value, :attributes => @attributes, :type => @type}
    end
      
    def next_element
      @name = @node.name
      unless @name
        reading_ends
        return
      end

      @type = @node.node_type
      if @type==TYPE_END_OF_FILE
        reading_ends
        return
      end

      @attributes = @node.attributes if @node.attribute_count > 0

      @node.read

      @value = @node.value
      @value = @value.to_s.strip
      @value = nil if @value.length==0
    end

    def reading_ends
      @file.close rescue nil
      @file = nil
    end
  end
end

