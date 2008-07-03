-- classes for codebrowser
require 'class'

Project = class(function(p,name,baseDir,srcDir)
    p.name = name
    p.baseDir = baseDir
    p.srcDir = srcDir
    p.classes = {}
    p.srcFiles = {}
    p.packages = {}
    end)
    
function Project:__tostring()
    return self.name
end