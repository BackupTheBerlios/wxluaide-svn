-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")
-- dofile("treectrl.lua")

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
function myFrame:CreateTreeCtrl()
    
    tree = wx.wxTreeCtrl(self.frame, wx.wxID_ANY,
            wx.wxPoint(0,0), wx.wxSize(160,250),
            wx.wxTR_DEFAULT_STYLE + wx.wxNO_BORDER);
            
    local root = tree:AddRoot("Project",0);

    local items = {}
    items[#items+1] = tree:AppendItem(root,"item 1",0)
    items[#items+1] = tree:AppendItem(root,"item 2",0)
    return tree
end
function myFrame:projectTree()
    -- self.tree = wx.wxTreeCtrl(parent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(-1,200), wx.wxTR_LINES_AT_ROOT + wx.wxTR_HAS_BUTTONS)
end

function myFrame:init()
    self:idInit()
    
    self.frame = wx.wxFrame(wx.NULL,
                        wx.wxID_ANY,
                        "wxAUI Sample Application",
                        wx.wxDefaultPosition,
                        wx.wxSize(800, 600));
    
    -- set up menu bar
    self.menubar = wx.wxMenuBar()
    self.frame:SetMenuBar(self.menubar)
    self:fileMenu()
    
    -- set up aui manager
    self.frame.m_mgr = wxaui.wxAuiManager()
    self.frame.m_mgr:SetManagedWindow(self.frame)
    
    -- status bar
    self.frame:CreateStatusBar()
    self.frame:GetStatusBar():SetStatusText("Ready")

    -- testing
    self.m_notebook_style = wxaui.wxAUI_NB_DEFAULT_STYLE + wxaui.wxAUI_NB_TAB_EXTERNAL_MOVE + wx.wxNO_BORDER;
    local w,h = self.frame:GetClientSizeWH();
    local ctrl = wxaui.wxAuiNotebook(self.frame, wx.wxID_ANY,
                                    wx.wxPoint(w,h), --wx.wxPoint(client_size.x, client_size.y),
                                    wx.wxSize(430,200),
                                    self.m_notebook_style);
    local leftTree = self:CreateTreeCtrl()
    -- wx.wxMessageBox("What is treeCtrl " .. type(treeCtrl),"",wx.wxOK+wx.wxICON_EXCLAMATION,wx.NULL)
    self.frame.m_mgr:AddPane(leftTree,wxaui.wxAuiPaneInfo():Name("test"):Caption("Blah"):Left():Layer(1):Position(1):CloseButton(true):MaximizeButton(true))
    
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
