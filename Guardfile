# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'sprockets', :destination => 'build',  :asset_paths => ['lib', 'vendor'] do #, :minify => true
  watch (%r{^lib/js/.*}) {|m| "lib/js/jquery.json-editor.js" }
  watch (%r{^lib/css/.*}) {|m| "lib/css/jquery.json-editor.css.scss" }
end

guard 'sprockets', :destination => 'spec/compiled', :asset_paths => ['spec'] do
  watch (%r{^spec/.*\.(coffee|js)})# { |m| "spec/specs.js" }
end
