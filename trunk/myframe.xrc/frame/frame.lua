-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

myFrame = {}

function myFrame:new(frm)
    frm = frm or {}
    setmetatable(frm, self)
    self.__index = self
    self.ID_IDCOUNTER = wx.wxID_HIGHEST + 1
    return frm
end
function myFrame:NewID()
    self.ID_IDCOUNTER = self.ID_IDCOUNTER + 1
    return self.ID_IDCOUNTER
end
function myFrame:idInit()
    -- File menu
    self.ID_NEW              = wx.wxID_NEW
    self.ID_OPEN             = wx.wxID_OPEN
    self.ID_CLOSE            = self:NewID()
    self.ID_SAVE             = wx.wxID_SAVE
    self.ID_SAVEAS           = wx.wxID_SAVEAS
    self.ID_SAVEALL          = self:NewID()
    self.ID_EXIT             = wx.wxID_EXIT
end

function myFrame:fileMenu()
    -- create standard menus
    local fileMenu = wx.wxMenu{
            { self.ID_NEW,      "&New"        },
            { self.ID_OPEN,     "&Open File"   },
            { self.ID_CLOSE,    "&Close File"     },
            { self.ID_SAVE,     "&Save File" },
            { self.ID_EXIT,     "E&xit" }}
            
    self.menubar:Append(fileMenu,"&File")
    self.frame:Connect(self.ID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            self.frame:Close(true)
        end )
    
end

-- project tree control
function myFrame:projectTree()
    -- self.tree = wx.wxTreeCtrl(parent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(-1,200), wx.wxTR_LINES_AT_ROOT + wx.wxTR_HAS_BUTTONS)
end

function myFrame:init()
    self:idInit()
    self.xmlResource = wx.wxXmlResource()
    self.xmlResource:InitAllHandlers()
    
    self.xmlResource:Load("myframe.xrc")
    
    self.frame = wx.wxFrame()
    self.xmlResource:LoadFrame(self.frame, wx.NULL, "fmMain")
    
    -- set up menu bar
    self.menubar = wx.wxMenuBar()
    self.frame:SetMenuBar(self.menubar)
    self:fileMenu()

end

function myFrame:show()
    self.frame:Centre()
    self.frame:Show(true)

end

function myFrame:addMenu(m)
    self.menubar:Append(m, "&menu")
end

local frame = myFrame:new()
myFrame:init()
frame:show()

wx.wxGetApp():MainLoop()
