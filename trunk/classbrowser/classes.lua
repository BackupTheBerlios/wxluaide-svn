-- classes for codebrowser
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;lib/?.dll;/usr/local/luaaio/lib/?.so"
require 'class'
require 'lib/luasqlite3'

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

ProjMgr = class(function(pm)
    --[[
    ProjMgr is a class to manage, load and save projects
    
    ]]
    
   
    end)

    
function ProjMgr:loadProject(name)


end
    
-- db logic
Database = class(function(db)
    db.location = "./cbrowser.sql3"
    db.handle = sqlite3.open(db.location)
    
    end)
    
