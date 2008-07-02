-- part of browser.lua

dofile( "table.save-0.94.lua" )

local Project = {}
mt = {}
local projectList = {}

function Project:new(s)
    return setmetatable({ value = s or ''}, mt)
end
    
function Project:LoadList(dir)

return projects
end

function Project:Add(name,lang,dir,srcdir)
    local t = {}
    t.name = name
    t.dir = dir
    t.srcdir = srcdir
    -- TODO: read in source files
    t.srcfiles = {}
    t.packages = {}
    t.classes = {}

    projectList[name] = t
end


