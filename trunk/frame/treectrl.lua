-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

treeCtrl = {}

function treeCtrl:new(frame)
	local this = self.this
	tree = wx.wxTreeCtrl(frame, wx.wxID_ANY,
			wx.wxPoint(0,0), wx.wxSize(160,250),
			wx.wxTR_DEFAULT_STYLE + wx.wxNO_BORDER);
			
	self.root = tree:AddRoot("Project",0);
	local root = self.root
	
	self.items = {}
	local items = self.items
	items[#items+1] = tree:AppendItem(root,"item 1",0)
	items[#items+1] = tree:AppendItem(root,"item 2",0)
    return tree
end

