#########################################
#                                       #
#   Name : build.rake                   #
#   About : Build automation document   #
#           with the most basic build   #
#           rules.                      #
#                                       #
#########################################

require 'yaml'

# Pre-Process the Raw Markdown
rule '.ppmd' => '.md' do |f|
    sh "#{$PP} -o #{f.name} #{$PPOPTS_PRE} #{f.source}"    
end

# Generate Tex from Prerocessed Markdown 
rule '.tex' => '.ppmd' do |f|
    sh "#{$LC} -f markdown -w latex -o #{f.name} #{f.source} #{$LCOPTS_SA}"
end

# Pre-Process the Generated Tex File
#rule '.pptex' => '.tex' do |f|
#    sh "#{$PP} -o #{f.name} #{$PPOPTS_POST} #{f.source}"    
#end

# Generate PDFs from preprocessed markdown
rule '.pdf' => '.tex' do |f|
    sh "#{$PDF} #{f.source} #{$PDFOPTS}"
    # run again to make sure cross references are there
    sh "#{$PDF} #{f.source} #{$PDFOPTS}"
end

