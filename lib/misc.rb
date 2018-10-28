"""This script parses a yaml style config as follows:
	- yaml strings become variables
	- yaml hashes translate to objects with nested properties
All objects are declared as instance variables (@) by default
"""

require 'erb'
require 'json'
require 'yaml'

class DeepOpenStruct < OpenStruct
  def to_h
    convert_to_hash_recursive self.dup
  end

  def self.load item
    raise ArgumentError, "DeepOpenStruct must be passed a Hash or Array" unless(item.is_a?(Hash) || item.is_a?(Array))
    self.convert_from_hash_recursive item
  end

  private

  def self.convert_from_hash_recursive obj
    result = obj
    case result
      when Hash
        result = result.dup
        result.each do |k,v|
          result[k] = convert_from_hash_recursive(v)
        end
        result = DeepOpenStruct.new result
      when Array
        result = result.map { |v| convert_from_hash_recursive(v) }
    end
    result
  end

  def convert_to_hash_recursive obj
    result = obj
    case result
      when OpenStruct
        result = result.marshal_dump
        result.each do |k,v|
          result[k] = convert_to_hash_recursive(v)
        end
      when Array
        result = result.map { |v| convert_to_hash_recursive(v) }
    end
    result
  end
end

class Hash
  def to_o
    JSON.parse to_json, object_class: DeepOpenStruct
  end

end

class YAMLTasks

  def parse(yamlfile, toplevelkey)
	# check for vagrant config file
	if File.exist?(yamlfile)
			begin
				yaml_config = YAML.load(ERB.new(File.read(yamlfile)).result(binding))
			rescue Exception => e
				warn("#{yamlfile} fails yaml syntax check!")
				raise("Error was #{e}")
			end
	else
		raise("Could not find config file! #{yamlfile}")
	end
	# check for toplevelkey section in config file and evaluate variables
	if !yaml_config[toplevelkey].nil?
		yaml_config[toplevelkey].each do |c,s|
			if yaml_config[toplevelkey][c].is_a?(Hash)
				if eval "defined?($#{c})"
					# Incoming Hash
					eval "$#{c} = yaml_config[toplevelkey][c].merge!($#{c}.to_h) {|k, o, n| n}"
					eval "$#{c} = $#{c}.to_o"
				else
					eval "$#{c} = yaml_config[toplevelkey][c].to_o"
				end
			else
				eval "$#{c} = '#{s}'"
			end
		end
	else
		raise("No #{toplevelkey} key found in your #{yamlfile}. Consult #{yamlfile}.yaml.sample or the README")
	end
  end

end
