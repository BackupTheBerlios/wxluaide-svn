
-- browser.lua
-- dennis sacks
-- uses code from the wxlua editor sample application

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;lib/?.dll;/usr/local/luaaio/lib/?.so"
require("wx")
dofile( "projects.lua" )

local ID_IDCOUNTER = wx.wxID_HIGHEST + 1
function NewID()
    ID_IDCOUNTER = ID_IDCOUNTER + 1
    return ID_IDCOUNTER
end
-- Equivalent to C's "cond ? a : b", all terms will be evaluated
function iff(cond, a, b) if cond then return a else return b end end

-- Does the num have all the bits in value
function HasBit(value, num)
    for n = 32, 0, -1 do
        local b = 2^n
        local num_b = num - b
        local value_b = value - b
        if num_b >= 0 then
            num = num_b
        else
            return true -- already tested bits in num
        end
        if value_b >= 0 then
            value = value_b
        end
        if (num_b >= 0) and (value_b < 0) then
            return false
        end
    end

    return true
end
-- globals
local frame
local editorID         = 100
-- File menu
local ID_NEW              = wx.wxID_NEW
local ID_OPEN             = wx.wxID_OPEN
local ID_CLOSE            = NewID()
local ID_SAVE             = wx.wxID_SAVE
local ID_SAVEAS           = wx.wxID_SAVEAS
local ID_SAVEALL          = NewID()
local ID_EXIT             = wx.wxID_EXIT
-- Edit menu
local ID_CUT              = wx.wxID_CUT
local ID_COPY             = wx.wxID_COPY
local ID_PASTE            = wx.wxID_PASTE
local ID_SELECTALL        = wx.wxID_SELECTALL
local ID_UNDO             = wx.wxID_UNDO
local ID_REDO             = wx.wxID_REDO
local ID_AUTOCOMPLETE     = NewID()
local ID_AUTOCOMPLETE_ENABLE = NewID()
local ID_COMMENT          = NewID()
local ID_FOLD             = NewID()
-- Find menu
local ID_FIND             = wx.wxID_FIND
local ID_FINDNEXT         = NewID()
local ID_FINDPREV         = NewID()
local ID_REPLACE          = NewID()
local ID_GOTOLINE         = NewID()
local ID_SORT             = NewID()
-- Debug menu
local ID_TOGGLEBREAKPOINT = NewID()
local ID_COMPILE          = NewID()
local ID_RUN              = NewID()
local ID_ATTACH_DEBUG     = NewID()
local ID_START_DEBUG      = NewID()
local ID_USECONSOLE       = NewID()

local ID_STOP_DEBUG       = NewID()
local ID_STEP             = NewID()
local ID_STEP_OVER        = NewID()
local ID_STEP_OUT         = NewID()
local ID_CONTINUE         = NewID()
local ID_BREAK            = NewID()
local ID_VIEWCALLSTACK    = NewID()
local ID_VIEWWATCHWINDOW  = NewID()
local ID_SHOWHIDEWINDOW   = NewID()
local ID_CLEAROUTPUT      = NewID()
local ID_DEBUGGER_PORT    = NewID()
-- Help menu
local ID_ABOUT            = wx.wxID_ABOUT
-- Watch window menu items
local ID_WATCH_LISTCTRL   = NewID()
local ID_ADDWATCH         = NewID()
local ID_EDITWATCH        = NewID()
local ID_REMOVEWATCH      = NewID()
local ID_EVALUATEWATCH    = NewID()

-- Markers for editor marker margin
local BREAKPOINT_MARKER         = 1
local BREAKPOINT_MARKER_VALUE   = 2 -- = 2^BREAKPOINT_MARKER
local CURRENT_LINE_MARKER       = 2
local CURRENT_LINE_MARKER_VALUE = 4 -- = 2^CURRENT_LINE_MARKER

-- ASCII values for common chars
local char_CR  = string.byte("\r")
local char_LF  = string.byte("\n")
local char_Tab = string.byte("\t")
local char_Sp  = string.byte(" ")

local projectFile = ""

programName      = nil    -- the name of the wxLua program to be used when starting debugger
editorApp        = wx.wxGetApp()

debuggerServer     = nil    -- wxLuaDebuggerServer object when debugging, else nil
debuggerServer_    = nil    -- temp wxLuaDebuggerServer object for deletion
debuggee_running   = false  -- true when the debuggee is running
debugger_destroy   = 0      -- > 0 if the debugger is to be destroyed in wxEVT_IDLE
debuggee_pid       = 0      -- pid of the debuggee process
debuggerPortNumber = 1551   -- the port # to use for debugging

-- wxWindow variables
frame            = nil    -- wxFrame the main top level window
splitter         = nil    -- wxSplitterWindow for the notebook and errorLog
notebook         = nil    -- wxNotebook of editors
errorLog         = nil    -- wxStyledTextCtrl log window for messages
watchWindow      = nil    -- the watchWindow, nil when not created
watchListCtrl    = nil    -- the child listctrl in the watchWindow

in_evt_focus     = false  -- true when in editor focus event to avoid recursion
openDocuments    = {}     -- open notebook editor documents[winId] = {
                          --   editor     = wxStyledTextCtrl,
                          --   index      = wxNotebook page index,
                          --   filePath   = full filepath, nil if not saved,
                          --   fileName   = just the filename,
                          --   modTime    = wxDateTime of disk file or nil,
                          --   isModified = bool is the document modified? }
ignoredFilesList = {}
editorID         = 100    -- window id to create editor pages with, incremented for new editors
exitingProgram   = false  -- are we currently exiting, ID_EXIT
autoCompleteEnable = true -- value of ID_AUTOCOMPLETE_ENABLE menu item
wxkeywords       = nil    -- a string of the keywords for scintilla of wxLua's wx.XXX items
font             = nil    -- fonts to use for the editor
fontItalic       = nil
function OnShowMessage()
    wx.wxMessageBox("Hey there, how goes it?")
end

function OnQuit()
    dialog:Show(false)
    dialog:Destroy()
    return
end

function main()

    xmlResource = wx.wxXmlResource()
    xmlResource:InitAllHandlers()
    local xrcFilename = "classbrowser.xrc"

    while not xmlResource:Load(xrcFilename) do
    -- must unload the file before we try again
    xmlResource:Unload(xrcFilename)
    
    wx.wxMessageBox("Error loading xrc resource")
    return
    end


    frame = wx.wxFrame()
    if not xmlResource:LoadFrame(frame, wx.NULL, "browserFrame") then
    wx.wxMessageBox("Error loading xrc resource")
    return
    end

    -- get resources
    local pkgTreeCtrl = frame:FindWindow(xmlResource.GetXRCID("pkgTreeCtrl")):DynamicCast("wxTreeCtrl")
    local classTreeCtrl = frame:FindWindow(xmlResource.GetXRCID("classTreeCtrl")):DynamicCast("wxTreeCtrl")
    local classListBox = frame:FindWindow(xmlResource.GetXRCID("classListBox")):DynamicCast("wxListBox")
    classTreeCtrl:SetSize(-1,450)

    -- set up method Editor
    local methodPanel = frame:FindWindow(xmlResource.GetXRCID("methodPanel"))
    local methodSizer = wx.wxGridSizer(1,1,0,0)
    local methodEditor = CreateEditor(methodPanel,"method Source")
    methodSizer:Add(methodEditor, 1, wx.wxALL+wx.wxEXPAND, 1 )
    methodPanel:SetSizer(methodSizer)
    methodPanel:Layout()
    methodSizer:Fit(methodPanel)
    
       -- set up class Editor
    local classPanel = frame:FindWindow(xmlResource.GetXRCID("classPanel"))
    local classSizer = wx.wxGridSizer(1,1,0,0)
    local classEditor = CreateEditor(classPanel,"class Source")
    classSizer:Add(classEditor, 1, wx.wxALL+wx.wxEXPAND, 1 )
    classPanel:SetSizer(classSizer)
    classPanel:Layout()
    classSizer:Fit(classPanel)
    
       -- set up method Editor
    local commentsPanel = frame:FindWindow(xmlResource.GetXRCID("commentsPanel"))
    local commentsSizer = wx.wxGridSizer(1,1,0,0)
    local commentsEditor = CreateEditor(commentsPanel,"comments Source")
    commentsSizer:Add(commentsEditor, 1, wx.wxALL+wx.wxEXPAND, 1 )
    commentsPanel:SetSizer(commentsSizer)
    commentsPanel:Layout()
    commentsSizer:Fit(commentsPanel)
    

    -- methodSizer:Add(control, 0, wx.wxALIGN_LEFT+wx.wxALL, 5)
    --button1 = xmlResource.GetXRCID("m_button1")
    --button2 = xmlResource.GetXRCID("m_button2")

    --dialog:Connect(button1, wx.wxEVT_COMMAND_BUTTON_CLICKED, OnShowMessage)
    --dialog:Connect(button2, wx.wxEVT_COMMAND_BUTTON_CLICKED, OnQuit)


    -- frame:Show(true)



end

-- Update the statusbar text of the frame using the given editor.
--  Only update if the text has changed.
statusTextTable = { "OVR?", "R/O?", "Cursor Pos" }

-- TODO: get this to update current editor, not methodEditor
function UpdateStatusText(editor)
    local texts = { "", "", "" }
    local editor = methodEditor
    if frame and editor then
        local pos  = editor:GetCurrentPos()
        local line = editor:LineFromPosition(pos)
        local col  = 1 + pos - editor:PositionFromLine(line)

        texts = { iff(editor:GetOvertype(), "OVR", "INS"),
                  iff(editor:GetReadOnly(), "R/O", "R/W"),
                  "Ln "..tostring(line + 1).." Col "..tostring(col) }
    end

    if frame then
        for n = 1, 3 do
            if (texts[n] ~= statusTextTable[n]) then
                frame:SetStatusText(texts[n], n)
                statusTextTable[n] = texts[n]
            end
        end
    end
end

function CreateEditor(parent,name)
if wx.__WXMSW__ then
    font       = wx.wxFont(10, wx.wxFONTFAMILY_MODERN, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_NORMAL, false, "Andale Mono")
    fontItalic = wx.wxFont(10, wx.wxFONTFAMILY_MODERN, wx.wxFONTSTYLE_ITALIC, wx.wxFONTWEIGHT_NORMAL, false, "Andale Mono")
else
    font       = wx.wxFont(10, wx.wxFONTFAMILY_MODERN, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_NORMAL, false, "")
    fontItalic = wx.wxFont(10, wx.wxFONTFAMILY_MODERN, wx.wxFONTSTYLE_ITALIC, wx.wxFONTWEIGHT_NORMAL, false, "")
end
    local editor = wxstc.wxStyledTextCtrl(parent, editorID,
                                          wx.wxDefaultPosition, wx.wxDefaultSize,
                                          wx.wxSUNKEN_BORDER)

    editorID = editorID + 1 -- increment so they're always unique

    editor:SetBufferedDraw(true)
    editor:StyleClearAll()

    editor:SetFont(font)
    editor:StyleSetFont(wxstc.wxSTC_STYLE_DEFAULT, font)
    for i = 0, 32 do
        editor:StyleSetFont(i, font)
    end

    editor:StyleSetForeground(0,  wx.wxColour(128, 128, 128)) -- White space
    editor:StyleSetForeground(1,  wx.wxColour(0,   127, 0))   -- Block Comment
    editor:StyleSetFont(1, fontItalic)
    --editor:StyleSetUnderline(1, false)
    editor:StyleSetForeground(2,  wx.wxColour(0,   127, 0))   -- Line Comment
    editor:StyleSetFont(2, fontItalic)                        -- Doc. Comment
    --editor:StyleSetUnderline(2, false)
    editor:StyleSetForeground(3,  wx.wxColour(127, 127, 127)) -- Number
    editor:StyleSetForeground(4,  wx.wxColour(0,   127, 127)) -- Keyword
    editor:StyleSetForeground(5,  wx.wxColour(0,   0,   127)) -- Double quoted string
    editor:StyleSetBold(5,  true)
    --editor:StyleSetUnderline(5, false)
    editor:StyleSetForeground(6,  wx.wxColour(127, 0,   127)) -- Single quoted string
    editor:StyleSetForeground(7,  wx.wxColour(127, 0,   127)) -- not used
    editor:StyleSetForeground(8,  wx.wxColour(0,   127, 127)) -- Literal strings
    editor:StyleSetForeground(9,  wx.wxColour(127, 127, 0))  -- Preprocessor
    editor:StyleSetForeground(10, wx.wxColour(0,   0,   0))   -- Operators
    --editor:StyleSetBold(10, true)
    editor:StyleSetForeground(11, wx.wxColour(0,   0,   0))   -- Identifiers
    editor:StyleSetForeground(12, wx.wxColour(0,   0,   0))   -- Unterminated strings
    editor:StyleSetBackground(12, wx.wxColour(224, 192, 224))
    editor:StyleSetBold(12, true)
    editor:StyleSetEOLFilled(12, true)

    editor:StyleSetForeground(13, wx.wxColour(0,   0,  95))   -- Keyword 2 highlighting styles
    editor:StyleSetForeground(14, wx.wxColour(0,   95, 0))    -- Keyword 3
    editor:StyleSetForeground(15, wx.wxColour(127, 0,  0))    -- Keyword 4
    editor:StyleSetForeground(16, wx.wxColour(127, 0,  95))   -- Keyword 5
    editor:StyleSetForeground(17, wx.wxColour(35,  95, 175))  -- Keyword 6
    editor:StyleSetForeground(18, wx.wxColour(0,   127, 127)) -- Keyword 7
    editor:StyleSetBackground(18, wx.wxColour(240, 255, 255)) -- Keyword 8

    editor:StyleSetForeground(19, wx.wxColour(0,   127, 127))
    editor:StyleSetBackground(19, wx.wxColour(224, 255, 255))
    editor:StyleSetForeground(20, wx.wxColour(0,   127, 127))
    editor:StyleSetBackground(20, wx.wxColour(192, 255, 255))
    editor:StyleSetForeground(21, wx.wxColour(0,   127, 127))
    editor:StyleSetBackground(21, wx.wxColour(176, 255, 255))
    editor:StyleSetForeground(22, wx.wxColour(0,   127, 127))
    editor:StyleSetBackground(22, wx.wxColour(160, 255, 255))
    editor:StyleSetForeground(23, wx.wxColour(0,   127, 127))
    editor:StyleSetBackground(23, wx.wxColour(144, 255, 255))
    editor:StyleSetForeground(24, wx.wxColour(0,   127, 127))
    editor:StyleSetBackground(24, wx.wxColour(128, 155, 255))

    editor:StyleSetForeground(32, wx.wxColour(224, 192, 224))  -- Line number
    editor:StyleSetBackground(33, wx.wxColour(192, 192, 192))  -- Brace highlight
    editor:StyleSetForeground(34, wx.wxColour(0,   0,   255))
    editor:StyleSetBold(34, true)                              -- Brace incomplete highlight
    editor:StyleSetForeground(35, wx.wxColour(255, 0,   0))
    editor:StyleSetBold(35, true)                              -- Indentation guides
    editor:StyleSetForeground(37, wx.wxColour(192, 192, 192))
    editor:StyleSetBackground(37, wx.wxColour(255, 255, 255))

    editor:SetUseTabs(false)
    editor:SetTabWidth(4)
    editor:SetIndent(4)
    editor:SetIndentationGuides(true)

    editor:SetVisiblePolicy(wxstc.wxSTC_VISIBLE_SLOP, 3)
    --editor:SetXCaretPolicy(wxstc.wxSTC_CARET_SLOP, 10)
    --editor:SetYCaretPolicy(wxstc.wxSTC_CARET_SLOP, 3)

    editor:SetMarginWidth(0, editor:TextWidth(32, "9999_")) -- line # margin

    editor:SetMarginWidth(1, 16) -- marker margin
    editor:SetMarginType(1, wxstc.wxSTC_MARGIN_SYMBOL)
    editor:SetMarginSensitive(1, true)

    editor:MarkerDefine(BREAKPOINT_MARKER,   wxstc.wxSTC_MARK_ROUNDRECT, wx.wxWHITE, wx.wxRED)
    editor:MarkerDefine(CURRENT_LINE_MARKER, wxstc.wxSTC_MARK_ARROW,     wx.wxBLACK, wx.wxGREEN)

    editor:SetMarginWidth(2, 16) -- fold margin
    editor:SetMarginType(2, wxstc.wxSTC_MARGIN_SYMBOL)
    editor:SetMarginMask(2, wxstc.wxSTC_MASK_FOLDERS)
    editor:SetMarginSensitive(2, true)

    editor:SetFoldFlags(wxstc.wxSTC_FOLDFLAG_LINEBEFORE_CONTRACTED +
                        wxstc.wxSTC_FOLDFLAG_LINEAFTER_CONTRACTED)

    editor:SetProperty("fold", "1")
    editor:SetProperty("fold.compact", "1")
    editor:SetProperty("fold.comment", "1")

    local grey = wx.wxColour(128, 128, 128)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDEROPEN,    wxstc.wxSTC_MARK_BOXMINUS, wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDER,        wxstc.wxSTC_MARK_BOXPLUS,  wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDERSUB,     wxstc.wxSTC_MARK_VLINE,    wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDERTAIL,    wxstc.wxSTC_MARK_LCORNER,  wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDEREND,     wxstc.wxSTC_MARK_BOXPLUSCONNECTED,  wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDEROPENMID, wxstc.wxSTC_MARK_BOXMINUSCONNECTED, wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDERMIDTAIL, wxstc.wxSTC_MARK_TCORNER,  wx.wxWHITE, grey)
    grey:delete()



    editor:Connect(wxstc.wxEVT_STC_CHARADDED,
            function (event)
                -- auto-indent
                local ch = event:GetKey()
                if (ch == char_CR) or (ch == char_LF) then
                    local pos = editor:GetCurrentPos()
                    local line = editor:LineFromPosition(pos)

                    if (line > 0) and (editor:LineLength(line) == 0) then
                        local indent = editor:GetLineIndentation(line - 1)
                        if indent > 0 then
                            editor:SetLineIndentation(line, indent)
                            editor:GotoPos(pos + indent)
                        end
                    end
                elseif autoCompleteEnable then -- code completion prompt
                    local pos = editor:GetCurrentPos()
                    local start_pos = editor:WordStartPosition(pos, true)
                    -- must have "wx.X" otherwise too many items
                    if (pos - start_pos > 0) and (start_pos > 2) then
                        local range = editor:GetTextRange(start_pos-3, start_pos)
                        if range == "wx." then
                            local commandEvent = wx.wxCommandEvent(wx.wxEVT_COMMAND_MENU_SELECTED,
                                                                   ID_AUTOCOMPLETE)
                            wx.wxPostEvent(frame, commandEvent)
                        end
                    end
                end
            end)

    editor:Connect(wxstc.wxEVT_STC_USERLISTSELECTION,
            function (event)
                local pos = editor:GetCurrentPos()
                local start_pos = editor:WordStartPosition(pos, true)
                editor:SetSelection(start_pos, pos)
                editor:ReplaceSelection(event:GetText())
            end)

    editor:Connect(wxstc.wxEVT_STC_SAVEPOINTREACHED,
            function (event)
                -- TODO SetDocumentModified(editor:GetId(), false)
            end)

    editor:Connect(wxstc.wxEVT_STC_SAVEPOINTLEFT,
            function (event)
                -- TODO SetDocumentModified(editor:GetId(), true)
            end)

    editor:Connect(wxstc.wxEVT_STC_UPDATEUI,
            function (event)
                UpdateStatusText(editor)
            end)

    editor:Connect(wx.wxEVT_SET_FOCUS,
            function (event)
                event:Skip()
                if in_evt_focus or exitingProgram then return end
                in_evt_focus = true
                -- TODO IsFileAlteredOnDisk(editor)
                in_evt_focus = false
            end)


    return editor
end


    

main()
frame:Show(true)
wx.wxGetApp():MainLoop()

    
