require 'securerandom'

module Jekyll
	class GoogleChartTool < Liquid::Block
		def initialize(tag_name, markup, tokens)
			mydata = Hash[markup.scan /(\w+)=(\w+|'.+'|".+")/]
			mydata.each do |key, value|
				mydata[key] = mydata[key].gsub(/\A'(.+)'\z/, '\1')
				mydata[key] = mydata[key].gsub(/\A\"(.+)\"\z/, '\1')
			end
			print "#{mydata}\n"

			@options = mydata["options"]
			@type = mydata["type"]
			@test = mydata["test"]
			@width = 800
			@height = 500

			if mydata["size"] =~ /(\d+)x(\d+)/
				@width = $1
				@height = $2
			end
			super
		end

		def render(context)
			code = super
			data_str = "\n"
			lines = code.split("\n")
			lines.each do |line|
				if line != "" 
					if data_str.length > 1 
						data_str = data_str + ","
					end
					data_str = data_str + "[" + line + "]\n"
				end
			end
			options_str = @options
			div_id = SecureRandom.uuid.gsub(/-/, '_')

			if @test == "true"
				open_editor = <<-EOF
<input type='button' onclick='openEditor_#{div_id}()' value='Open Editor'> 
				EOF
			else
				open_editor = ""
			end
			retval = <<-EOF
<script type='text/javascript' src='https://www.google.com/jsapi'></script>
<script type='text/javascript'>
google.load('visualization', '1', {packages: ['charteditor']});
google.setOnLoadCallback(drawVisualization);
var wr;
function drawVisualization() {
	wr = new google.visualization.ChartWrapper({
		chartType: '#{@type}',
		dataTable: [#{data_str}],
		options: { #{options_str} },
		containerId: '#{div_id}'
	});
	wr.draw();
}
function openEditor_#{div_id}() {
	var editor = new google.visualization.ChartEditor();
	google.visualization.events.addListener(
		editor, 'ok',
		function() {
			wr = editor.getChartWrapper();
			wr.draw('#{div_id}');
			alert(JSON.stringify(wr.getOptions()));
		}
	);
	editor.openDialog(wr);
}
</script>
#{open_editor}
<div id="#{div_id}" style="width: #{@width}px; height: #{@height}px;"></div> 
			EOF
			return retval
		end
	end
end

Liquid::Template.register_tag('gct', Jekyll::GoogleChartTool)
