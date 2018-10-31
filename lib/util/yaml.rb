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

  def deep_merge(second)
      merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
      self.merge(second, &merger)
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
				abort("Error was #{e}")
			end
	else
		abort("Could not find config file! #{yamlfile}\nAre you in the project root? #{$_VAGRANT_PROJECT_ROOT}")
	end
	# check for toplevelkey section in config file and evaluate variables
	if !yaml_config[toplevelkey].nil?
		yaml_config[toplevelkey].each do |c,s|
			if yaml_config[toplevelkey][c].is_a?(Hash)
				if eval "defined?($#{c})"
          eval "@_defaults = $#{c}.to_h"
          # Merge incoming options, keeping new values
          eval "@_options = $#{c}.to_h.deep_merge(yaml_config[toplevelkey][c]) { |key, old, new | new }"
          # Convert all options keys to symbols where possible
					eval "@_options = @_options.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}"
          # Define new options
          eval "@new_options = @_options.deep_merge(@_defaults){ |key, option, default| 
            option
          }"
          # Define merged options
          eval "@merged_options = @_options.merge(@_defaults) { |key, option, default| 
          if option.respond_to?('merge') and option.is_a?(Hash)
            # Merge in nested hashes
            default.deep_merge(option.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo})
          else
            option
          end
          }.to_o"
          eval "$#{c} = @merged_options"
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
