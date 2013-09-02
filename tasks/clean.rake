#########################################
#                                       #
#   Name : clean.rake                   #
#   About : Basic Cleaning tasks for    #
#            subfolders.                #
#                                       #
#########################################

task :clean => ["clean:default"] 

namespace :clean do

    task :default => :temp
    
    task :temp do
        fl = FileList.new()
        fl.add($tempfiles)
        fl.existing!
        fl.each do |f|
            rm_rf f
        end 
    end

    task :all do
        fl = FileList.new()
        fl.add("*")
        fl.existing!
        fl.exclude { |f|  $filelist.include?(f) }
        fl.each do |f|
            rm_rf f
        end 
    end

end
