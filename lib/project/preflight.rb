require 'project/requirements'

missing_plugins = VenvProjectRequirements::VenvPlugins.check_plugins
if not missing_plugins.empty?
  $logger.error($warnings.missing_plugins % { plugins: missing_plugins.join("\n") })
end