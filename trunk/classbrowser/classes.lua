-- classes for codebrowser
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;lib/?.dll;/usr/local/luaaio/lib/?.so"
require 'class'
require 'lib/luasqlite3'
require 'tablesave'

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
    db.location = "./cbrowser.db3"
    db.db = assert(sqlite3.open(db.location))
    end)
	
function Database:loadSettings()
	local row = self.db:first_row("select settings from settings")
        return table.load(row.settings)
end

function Database:getProjectList()
    local projectList = {}
    for row in self.db:rows("select oid, name, data from project") do
	projectList[row.name] = table.load(row.data)
    end
    
    return projectList
end

function Database:createProject(name, data)
    local insert_stmt = self.db:prepare[[
	insert into project(name,data) values(?,?)
    ]]
    
    insert_stmt:bind(name,table.save(data))
    insert_stmt:exec()
end

function Database:saveSettings(t)
        local tb = {}
        tb.settings = table.save(t)
	local settingsStmt = assert(self.db:prepare[[
        BEGIN TRANSACTION;
		INSERT INTO settings(settings) VALUES (:settings);
	COMMIT
	]])
	settingsStmt:bind(tb)
	settingsStmt:exec()
end
    
