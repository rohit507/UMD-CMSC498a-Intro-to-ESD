#########################################
#                                       #
#   Name : Rakefile                     #
#   About : Common Chapter Automation   #
#                                       #
#########################################

import "#{$ROOT_DIR}settings.rake"

# Import each of the task files
Dir.glob("#{$ROOT_DIR}/tasks/*.rake").each { |r| import r }

