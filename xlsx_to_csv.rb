# Fast locale uses this to convert to relavent format.
# Contact anthony.gonsalves@philips.com
# Helper method to convert to relavant format. xlsx to csv

require 'roo'

def xlsx_to_csv(source, destination)
  if source =~ /xlsx$/
    excel = Roo::Excelx.new(source)
  else
    excel = Roo::Excel.new(source)
  end

  open(destination, 'w+') do |output|
    2.upto(excel.last_row) do |line|
      output.write CSV.generate_line excel.row(line)
    end
  end
end
