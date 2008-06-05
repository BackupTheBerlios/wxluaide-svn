------------------------------------------------------------------------------------------
--          globals
------------------------------------------------------------------------------------------

local appName="wxSME"
local appFile
local appDocument={filePath="",fileName="",modTime={},isModified=false}


local frame  --parent window
local editor  --edit surface
local menu  --main menu

-- ASCII values for common chars
local char_CR  = string.byte("\r")
local char_LF  = string.byte("\n")
local char_Tab = string.byte("\t")
local char_Sp  = string.byte(" ")

local font             = nil 
local fontItalic      = nil


if wx.__WINDOWS__ then ---windows
    appFile = appName..".exe"
    font    = wx.wxFont(8, 
            wx.wxFONTFAMILY_MODERN, 
            wx.wxFONTSTYLE_NORMAL, 
            wx.wxFONTWEIGHT_NORMAL, 
            false, "Lucida Console")
    fontItalic = wx.wxFont(8, 
            wx.wxFONTFAMILY_MODERN, 
            wx.wxFONTSTYLE_ITALIC, 
            wx.wxFONTWEIGHT_NORMAL, 
            false, "Lucida Console")

else --- mac then??
    appFile = appName..".app"
    font   = wx.wxFont(12, 
            wx.wxFONTFAMILY_MODERN, 
            wx.wxFONTSTYLE_NORMAL, 
            wx.wxFONTWEIGHT_NORMAL, 
            false, "")
    fontItalic = wx.wxFont(12, 
            wx.wxFONTFAMILY_MODERN, 
            wx.wxFONTSTYLE_ITALIC, 
            wx.wxFONTWEIGHT_NORMAL, 
            false, "")
end

local ID_IDCOUNTER = wx.wxID_HIGHEST + 1



------------------------------------------------------------------------------------------
--          helper functions
------------------------------------------------------------------------------------------

-- Generate a unique new wxWindowID
function NewID()
    ID_IDCOUNTER = ID_IDCOUNTER + 1
    return ID_IDCOUNTER
end
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
function GetFileModTime(filePath)
    if filePath and (string.len(filePath) > 0) then
        local fn = wx.wxFileName(filePath)
        if fn:FileExists() then
            return fn:GetModificationTime()
        end
    end

    return nil
end
-- Equivalent to C's "cond ? a : b", all terms will be evaluated
function iff(cond, a, b) if cond then return a else return b end end
-- Start a program
function run(filePath) 
    return wx.wxProcess.Open(filePath, wx.wxEXEC_NOHIDE+wx.wxEXEC_ASYNC)
end

------------------------------------------------------------------------------------------
--          frame
------------------------------------------------------------------------------------------

frame = wx.wxFrame(
    wx.NULL, 
    wx.wxID_ANY, 
    appName,
    wx.wxDefaultPosition, 
    wx.wxSize(800,700),
    wx.wxDEFAULT_FRAME_STYLE
)



------------------------------------------------------------------------------------------
--          menu
------------------------------------------------------------------------------------------

-- File menu
local ID_NEW = wx.wxID_NEW
local ID_OPEN = wx.wxID_OPEN
local ID_BROWSE = NewID()
local ID_SAVE = wx.wxID_SAVE
local ID_SAVEAS = wx.wxID_SAVEAS
local ID_EXIT = wx.wxID_EXIT
-- Edit menu
local ID_UNDO = wx.wxID_UNDO
local ID_REDO  = wx.wxID_REDO
local ID_CUT = wx.wxID_CUT
local ID_COPY = wx.wxID_COPY
local ID_PASTE = wx.wxID_PASTE
local ID_DELETE = wx.wxID_DELETE
local ID_SELECTALL = wx.wxID_SELECTALL
local ID_FIND = wx.wxID_FIND
local ID_REPLACE = NewID()
local ID_UPPER = NewID()
local ID_LOWER = NewID()
local ID_INDENT = NewID()
local ID_UNINDENT = NewID()
-- View menu
local ID_WRAP = NewID()
local ID_FOLD= NewID()
local ID_UNFOLD = NewID()
-- Help menu
local ID_ABOUT = wx.wxID_ABOUT

function CreateMenu()
    menuBar = wx.wxMenuBar()
    fileMenu = wx.wxMenu({
        { ID_NEW,     "&New\tCtrl-N",        "Create a new window" },
        { },
        { ID_OPEN,    "&Open...\tCtrl-O",    "Open an existing script" },
        { ID_SAVE,    "&Save\tCtrl-S",       "Save the current script" },
        { ID_SAVEAS,  "Save &As...\tCtrl-D",  "Save the current script to a file with a new name" },
        { ID_BROWSE,    "&Browse To\tCtrl-B",    "Open the current script in a browser" },
        { },
        { ID_EXIT,    "&Quit\tCtrl-Q",        "Quit "..appName }})
    menuBar:Append(fileMenu, "&File")
    
    editMenu = wx.wxMenu{
        { ID_UNDO,      "&Undo\tCtrl-Z",       "Undo the last action" },
        { ID_REDO,      "&Redo\tCtrl-Y",       "Redo the last action undone" },
        { },
        { ID_CUT,       "Cu&t\tCtrl-X",        "Cut selected text to clipboard" },
        { ID_COPY,      "&Copy\tCtrl-C",       "Copy selected text to the clipboard" },
        { ID_PASTE,     "&Paste\tCtrl-V",      "Insert clipboard text at cursor" },
        { ID_DELETE,  "Delete\tDelete",  "Delete selected text" },
        { },
        { ID_SELECTALL, "Select A&ll\tCtrl-A", "Select all text in the editor" },
        { },
        { ID_FIND,      "&Find\tCtrl-F",       "Find the specified text" },
        { ID_REPLACE,      "&Replace\tCtrl-R",       "Replaces the specified text with different text" },
        { },
        { ID_UPPER,    "&Upper Case\tCtrl-U",       "Change selected text to upper case" },
        { ID_LOWER,      "&Lower Case\tCtrl-L",      "Change selected text to lower case" },
        { },
        { ID_INDENT,      "&Indent\tTab",       "Indent the selected text" },
        { ID_UNINDENT,      "&Unindent\tShift-Tab",       "Unindent the selected text" }
    }
    menuBar:Append(editMenu, "&Edit")
    viewMenu = wx.wxMenu{
        { ID_WRAP,      "&Word Wrap\tCtrl-W",       "Toggle word wrap" },
        { },
        { ID_FOLD,    "&Fold All\tCtrl-1",       "Folds all nodes" },
        { ID_UNFOLD,      "&Unfold All\tCtrl-2",      "Unfolds all nodes" }
    }
    menuBar:Append(viewMenu, "&View")
    helpMenu = wx.wxMenu{
        { ID_ABOUT,      "&About\t",       "About "..appName },
    }
    menuBar:Append(helpMenu, "&Help")
    frame:SetMenuBar(menuBar)
    return menuBar
end


------------------------------------------------------------------------------------------
--          editor
------------------------------------------------------------------------------------------




function CreateEditor(name)
    local editor = wxstc.wxStyledTextCtrl(frame, 1010,
                                          wx.wxDefaultPosition, wx.wxDefaultSize ,
                                          wx.wxSUNKEN_BORDER)
    editor:SetBufferedDraw(true)
    editor:StyleClearAll()
    editor:SetStyling(0, 0);
    editor:SetStyleBits(8)
    
    editor:SetLexer(wxstc.wxSTC_LEX_HTML)
    
    
    editor:SetFont(font)
    editor:StyleSetFont(wxstc.wxSTC_STYLE_DEFAULT, font)
    for i = 0, 127 do
        editor:StyleSetFont(i, font)
    end
    
    ------- HTML Styles
    
    editor:StyleSetForeground(0,  wx.wxColour(0, 0, 0)) -- Default
    editor:StyleSetForeground(1,  wx.wxColour(0, 0, 255))   -- Tag
    editor:StyleSetForeground(2,  wx.wxColour(0, 0, 255))   -- Tag Unknown
    editor:StyleSetForeground(3,  wx.wxColour(127, 179, 255)) -- Attribute
    editor:StyleSetForeground(5,  wx.wxColour(0,179, 179)) -- Number (width=4)
    editor:StyleSetForeground(6,  wx.wxColour(0,179, 179)) -- Double quoted string (width="4")
    editor:StyleSetForeground(7,  wx.wxColour(0, 179, 179)) -- Single quoted string (width='4')
    editor:StyleSetForeground(8,  wx.wxColour(127, 179, 255)) -- Other (=)
    editor:StyleSetForeground(9,  wx.wxColour(179,   179,  179))  -- Comment <!-- hi -->
    editor:StyleSetForeground(10,  wx.wxColour(0, 127, 0))   -- Entity  (&nbsp;)
    
    
    ------- XML Styles
    
    editor:StyleSetForeground(12, wx.wxColour(0, 0,  255))   -- XML Start (<?)
    editor:StyleSetForeground(13, wx.wxColour(0, 0,  255))   -- XML End (?>)
    editor:StyleSetForeground(14, wx.wxColour(255,  0,  0))    -- Script
    editor:StyleSetForeground(15, wx.wxColour(255,  0,  0))    -- ASP
    editor:StyleSetForeground(16, wx.wxColour(255,  0,  0))   -- ASPAT
    editor:StyleSetForeground(17, wx.wxColour(255,  0,  0))  -- CDATA
    editor:StyleSetForeground(18, wx.wxColour(0,  0,  255))  -- Question 
    
    
    ------- SGML Styles
    
    editor:StyleSetForeground(21, wx.wxColour(179,   0, 0))    -- SGML_DEFAULT
    editor:StyleSetForeground(24, wx.wxColour(179,   0, 0))    -- SGML_DOUBLESTRING
    editor:StyleSetForeground(25, wx.wxColour(179,   0, 0))    -- SGML_SIMPLESTRING
    editor:StyleSetForeground(26, wx.wxColour(179,   0, 0))    -- SGML_ERROR
    
    
    ------- JavaScript Styles
    
    editor:StyleSetForeground(41, wx.wxColour(0,   0, 0 ))   -- JS Default
    editor:StyleSetForeground(42, wx.wxColour(179,   179,  179))    -- JS comment 
    editor:StyleSetForeground(43, wx.wxColour(179,   179,  179))   -- JS comment Line
    editor:StyleSetForeground(44, wx.wxColour(179,   179,  179))  --  JS comment DOC
    editor:StyleSetForeground(45, wx.wxColour(0,   0, 255))    -- JS number
    editor:StyleSetForeground(46, wx.wxColour(0,   0, 0))    -- JS word
    editor:StyleSetForeground(47, wx.wxColour(0,   0, 255))    -- JS keyword
    editor:StyleSetForeground(48, wx.wxColour(127,   0, 127))    -- JS double string
    editor:StyleSetForeground(49, wx.wxColour(127,   0, 127))    -- JS single string
    editor:StyleSetForeground(52, wx.wxColour(179,   0, 0))    -- JS regex
    
    
    ------- PHP Styles
    
    editor:StyleSetForeground(118, wx.wxColour(0, 0, 0 ))   -- PHP Default
    editor:StyleSetForeground(119, wx.wxColour(127,   0, 127))    -- PHP hstring
    editor:StyleSetForeground(120, wx.wxColour(127,   0, 127))   -- PHP simplestring
    editor:StyleSetForeground(121, wx.wxColour(0,   0, 255))  --  PHP word
    editor:StyleSetForeground(122, wx.wxColour(0,   0, 255))    -- PHP number
    editor:StyleSetForeground(123, wx.wxColour(0,   127, 0))    -- PHP $var
    editor:StyleSetForeground(124, wx.wxColour(179,   179,  179))    -- PHP Comment
    editor:StyleSetForeground(125, wx.wxColour(179,   179,  179))    -- PHP Comment Line
    editor:StyleSetForeground(126, wx.wxColour(0,   127, 0))    -- PHP hstring $var
    editor:StyleSetForeground(127, wx.wxColour(0,   0, 0))    -- PHP operator
    for i=118,127 do
        editor:StyleSetEOLFilled(i, true)
        editor:StyleSetBackground(i, wx.wxColour(249, 251, 249 )) 
    end
    
    
    ------- GUI Styles
    
    editor:StyleSetForeground(32, wx.wxColour(240, 220, 240))  -- Fold Line
    editor:StyleSetForeground(33, wx.wxColour(140,140, 140))  -- Line no.s
    editor:StyleSetForeground(36, wx.wxColour(255, 0,   0)) -- Control char (these shouldnt show up)
    editor:StyleSetForeground(37, wx.wxColour(220, 220, 220)) -- indent guides
    
    editor:SetUseTabs(true)
    editor:SetTabWidth(4)
    editor:SetIndent(4)
    editor:SetIndentationGuides(true)
    
    editor:SetVisiblePolicy(wxstc.wxSTC_VISIBLE_SLOP, 3)
    editor:SetMarginWidth(0, editor:TextWidth(32, "99999")) -- line no width
    editor:SetMarginWidth(1, 4) -- line no margin
    editor:SetMarginType(1, wxstc.wxSTC_MARGIN_SYMBOL)
    editor:SetMarginSensitive(1, true)
    
    editor:SetMarginWidth(2, 16) -- fold margin
    editor:SetMarginType(2, wxstc.wxSTC_MARGIN_SYMBOL)
    editor:SetMarginMask(2, wxstc.wxSTC_MASK_FOLDERS)
    editor:SetMarginSensitive(2, true)
    
    editor:SetProperty("fold", "1")
    editor:SetProperty("fold.html", "1")
    editor:SetProperty("fold.compact", "1")
    editor:SetProperty("fold.comment", "1")

    local grey = wx.wxColour(179,   179,  179)
    editor:MarkerDefine(
        wxstc.wxSTC_MARKNUM_FOLDEROPEN,    
        wxstc.wxSTC_MARK_BOXMINUS, 
        wx.wxWHITE, grey)
    editor:MarkerDefine(
        wxstc.wxSTC_MARKNUM_FOLDER,
        wxstc.wxSTC_MARK_BOXPLUS,  
        wx.wxWHITE, grey)
    editor:MarkerDefine(
        wxstc.wxSTC_MARKNUM_FOLDERSUB,
        wxstc.wxSTC_MARK_VLINE,
        wx.wxWHITE, grey)
    editor:MarkerDefine(
        wxstc.wxSTC_MARKNUM_FOLDERTAIL,
        wxstc.wxSTC_MARK_LCORNER,
        wx.wxWHITE, grey)
    editor:MarkerDefine(
        wxstc.wxSTC_MARKNUM_FOLDEREND,
        wxstc.wxSTC_MARK_BOXPLUSCONNECTED,
        wx.wxWHITE, grey)
    editor:MarkerDefine(
        wxstc.wxSTC_MARKNUM_FOLDEROPENMID, 
        wxstc.wxSTC_MARK_BOXMINUSCONNECTED, 
        wx.wxWHITE, grey)
    editor:MarkerDefine(
        wxstc.wxSTC_MARKNUM_FOLDERMIDTAIL, 
        wxstc.wxSTC_MARK_TCORNER, 
        wx.wxWHITE, grey)
    grey:delete()

    --- HTML tags 
    -----  if active then tags not in this list would show up under the "Tag Unknown" style 
    -----  however with the x* flavor of markup languages this seems outdated...
    if  onlyHTML then
      editor:SetKeyWords(0, 
        [[a b body br center cite code col colgroup dd dfn div dl dt em font form frame frameset 
        h1 h2 h3 h4 h5 h6 head hr html i iframe img input kbd li link map meta noframes noscript 
        object ol optgroup option p param pre q s samp script select small span strong style sub 
        sup table tbody td textarea tfoot th thead title tr tt u ul]])
    end

    ---js keywords (reserved words, base functions and document methods)
    editor:SetKeyWords(1,
        [[abstract boolean break byte case catch char class const continue debugger default delete
        do double     else enum export extends false final finally float for function goto if implements 
        import in instanceof int interface long native new null package private protected public return 
        short static super switch synchronized this throw throws transient true try typeof var void 
        volatile while with alert Array Date decodeURI decodeURIComponent encodeURI 
        encodeURIComponent escape eval Infinity isFinite isFinite NaN Number Object parseFloat 
        parseInt String undefined unescape document.anchors document.forms document.images 
        document.links document.cookie document.close document.domain document.getElementById 
        document.getElementsByName document.getElementsByTagName document.open 
        document.write document.writeIn document.lastModified document.referrer document.title 
        document.URL]])


-----php keywords (reserved words and common base functions)
    editor:SetKeyWords(4,
        [[addcslashes addslashes and  array array_chunk array_combine array_count_values array_diff 
        array_fill array_flip array_intersect array_keys array_key_exists array_map array_merge 
        array_pad array_pop array_push array_shift array_slice array_splice array_sum array_values 
        array_walk array_walk_recursive as base64_decode base64_encode break case chdir checkdate 
        chgrp chmod chop chown chr chroot class closedir closelog compact const constant continue 
        connection_aborted connection_status connection_timeout copy count count_chars current date 
        date_create date_format debug_zval_dump  declare default define defined delete die dir dirname 
        display_startup_errors display_errors do docref_ext docref_root each doubleval echo else elseif 
        empty end enddeclare endfor endforeach endif endswitch endwhile error_append_string error_log 
        error_prepend_string error_reporting eval exception exit explode extends extract ezmlm_hash 
        false fclose feof fflush file file_exists file_get_contents file_put_contents fileatime 
        filectime filegroup fileinode filemtime fileowner fileperms filesize filetype fopen for foreach 
        floatval fpassthru fputs fread fscanf fseek fstat ftell ftruncate fwrite function get_browser 
        getcwd getdate gettype get_defined_vars get_headers get_meta_tags get_resource_type glob global 
        idate header highlight_file highlight_string html_errors htmlentities htmlspecialchars 
        htmlspecialchars_ decode http_build_query if import implode request_variables ignore_repeated_errors
        ignore_repeated_source implode intval in_array include include_once isset is_array is_binary 
        is_bool is_buffer is_callable is_double is_dir is_executable is_float is_file is_int  is_integer 
        is_link is_long is_null is_numeric is_object is_readable is_real is_resource is_scalar is_string
        is_unicodeis_uploaded_file is_writable is_writeable join key link linkinfo list localtime 
        log_errors log_errors_max_len lstat mail mkdir mktime move_uploaded_file new NULL opendir openlog or 
        ord pack parse_ini_file parse_url pathinfo pclose popen php_check_syntax php_strip_whitespace pos 
        preg_grep preg_last_error preg_match_all preg_match preg_quote preg_replace_ callback preg_replace 
        preg_split prev print printf print_r private public range rawurldecode rawurlencode readdir 
        report_memleaks readfile readlink realpath rename rewind require require_once reset return rewinddir 
        rmdir rtrim scandir serialize setcookie setrawcookie settype show_source sizeof sleep split stat 
        static strchr str_ireplace str_replace strcmp strcoll stripcslashes stripslashes stristr strlen 
        strpos strstr strtok strtotime strval substr substr_compare substr_count substr_replace switch 
        symlink syslog tempnam time tmpfile touch track_errors trim true umask uniqid unlink unpack 
        unserialize unset use urldecode urlencode usleep var var_dump var_export vfprintf vprintf 
        vsprintf while xor]])

    ---code fold
    editor:Connect(wxstc.wxEVT_STC_MARGINCLICK,
        function (event)
            if event:GetMargin() == 2 then
                local line = editor:LineFromPosition(event:GetPosition())
                local level = editor:GetFoldLevel(line)
                if HasBit(level, wxstc.wxSTC_FOLDLEVELHEADERFLAG) then
                    editor:ToggleFold(line)
                end
            end
        end)
    
    
    editor:Connect(wxstc.wxEVT_STC_CHARADDED,
        function (event)
            appDocument.isModified=true
            -- auto-indent
            local ch = event:GetKey()
            if (ch == char_CR) or (ch == char_LF) then
                local pos = editor:GetCurrentPos()
                local line = editor:LineFromPosition(pos)
                local indent = editor:GetLineIndentation(line-1)
                editor:SetLineIndentation(line,indent)
                pos=editor:GetLineIndentPosition(line)
                editor:GotoPos(pos)
            end
        end)
    return editor
end



------------------------------------------------------------------------------------------
--          find/replace
------------------------------------------------------------------------------------------

findReplace = {
    dialog           = nil,   -- the wxDialog for find/replace
    replace          = false, -- is it a find or replace dialog
    fWholeWord       = false, -- match whole words
    fMatchCase       = false, -- case sensitive
    fDown            = true,  -- search downwards in doc
    fRegularExpr     = false, -- use regex
    fWrap            = false, -- search wraps around
    findTextArray    = {},    -- array of last entered find text
    findText         = "",    -- string to find
    replaceTextArray = {},    -- array of last entered replace text
    replaceText      = "",    -- string to replace find string with
    foundString      = false, -- was the string found for the last search
}


function EnsureRangeVisible(posStart, posEnd)
    if posStart > posEnd then
        posStart, posEnd = posEnd, posStart
    end

    local lineStart = editor:LineFromPosition(posStart)
    local lineEnd   = editor:LineFromPosition(posEnd)
    for line = lineStart, lineEnd do
        editor:EnsureVisibleEnforcePolicy(line)
    end
end


function SetSearchFlags()
    local flags = 0
    if findReplace.fWholeWord   then flags = wxstc.wxSTC_FIND_WHOLEWORD end
    if findReplace.fMatchCase   then flags = flags + wxstc.wxSTC_FIND_MATCHCASE end
    if findReplace.fRegularExpr then flags = flags + wxstc.wxSTC_FIND_REGEXP end
    editor:SetSearchFlags(flags)
end

function SetTarget(fDown, fInclude)
    local selStart = editor:GetSelectionStart()
    local selEnd =  editor:GetSelectionEnd()
    local len = editor:GetLength()
    local s, e
    if fDown then
        e= len
        s = iff(fInclude, selStart, selEnd +1)
    else
        s = 0
        e = iff(fInclude, selEnd, selStart-1)
    end
    if not fDown and not fInclude then s, e = e, s end
    editor:SetTargetStart(s)
    editor:SetTargetEnd(e)
    return e
end

function findReplace:HasText()
    return (findReplace.findText ~= nil) and (string.len(findReplace.findText) > 0)
end

function findReplace:GetSelectedString()
    local startSel = editor:GetSelectionStart()
    local endSel   = editor:GetSelectionEnd()
    if (startSel ~= endSel) 
    and (editor:LineFromPosition(startSel) == editor:LineFromPosition(endSel)) 
    then
        findReplace.findText = editor:GetSelectedText()
        findReplace.foundString = true
    end
end

function findReplace:FindString(reverse)
    if findReplace:HasText() then
        local fDown = iff(reverse, not findReplace.fDown, findReplace.fDown)
        local lenFind = string.len(findReplace.findText)
        SetSearchFlags()
        SetTarget(fDown)
        local posFind = editor:SearchInTarget(findReplace.findText)
        if (posFind == -1) and findReplace.fWrap then
            editor:SetTargetStart(iff(fDown, 0, editor:GetLength()))
            editor:SetTargetEnd(iff(fDown, editor:GetLength(), 0))
            posFind = editor:SearchInTarget(findReplace.findText)
        end
        if posFind == -1 then
            findReplace.foundString = false
            frame:SetStatusText("Find text not found.")
        else
            findReplace.foundString = true
            local start  = editor:GetTargetStart()
            local finish = editor:GetTargetEnd()
            EnsureRangeVisible(start, finish)
            editor:SetSelection(start, finish)
        end
    end
end

function ReplaceString(fReplaceAll)
    if findReplace:HasText() then
        local replaceLen = string.len(findReplace.replaceText)
        local findLen = string.len(findReplace.findText)
        local endTarget  = SetTarget(findReplace.fDown, fReplaceAll)
        if fReplaceAll then
            SetSearchFlags()
            local posFind = editor:SearchInTarget(findReplace.findText)
            if (posFind ~= -1)  then
                editor:BeginUndoAction()
                while posFind ~= -1 do
                    editor:ReplaceTarget(findReplace.replaceText)
                    editor:SetTargetStart(posFind + replaceLen)
                    endTarget = endTarget + replaceLen - findLen
                    editor:SetTargetEnd(endTarget)
                    posFind = editor:SearchInTarget(findReplace.findText)
                end
                editor:EndUndoAction()
            end
        else
            if findReplace.foundString then
                local start  = editor:GetSelectionStart()
                editor:ReplaceSelection(findReplace.replaceText)
                editor:SetSelection(start, start + replaceLen)
                findReplace.foundString = false
            end
            findReplace:FindString()
        end
    end
end

function CreateFindReplaceDialog(replace)
    local ID_FIND_NEXT   = 1
    local ID_REPLACE     = 2
    local ID_REPLACE_ALL = 3
    findReplace.replace  = replace

    local findDialog = wx.wxDialog(frame, wx.wxID_ANY, "Find/Replace",  wx.wxDefaultPosition, wx.wxDefaultSize)

    -- Create right hand buttons and sizer
    local findButton = wx.wxButton(findDialog, ID_FIND_NEXT, "&Find Next")
    findButton:SetDefault()
    local replaceButton =  wx.wxButton(findDialog, ID_REPLACE, "&Replace")
    local replaceAllButton = nil
    if (replace) then
        replaceAllButton =  wx.wxButton(findDialog, ID_REPLACE_ALL, "Replace &All")
    end
    local cancelButton =  wx.wxButton(findDialog, wx.wxID_CANCEL, "Cancel")

    local buttonsSizer = wx.wxBoxSizer(wx.wxVERTICAL)
    buttonsSizer:Add(findButton,    0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 3)
    buttonsSizer:Add(replaceButton, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 3)
    if replace then
        buttonsSizer:Add(replaceAllButton, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 3)
    end
    buttonsSizer:Add(cancelButton, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER,  3)

    -- Create find/replace text entry sizer
    local findStatText  = wx.wxStaticText( findDialog, wx.wxID_ANY, "Find: ")
    local findTextCombo = wx.wxTextCtrl (findDialog, wx.wxID_ANY, findReplace.findText,  wx.wxDefaultPosition, wx.wxDefaultSize)

    findTextCombo:SetFocus()

    local replaceStatText, replaceTextCombo
    if (replace) then
        replaceStatText  = wx.wxStaticText( findDialog, wx.wxID_ANY, "Replace: ")
        replaceTextCombo = wx.wxTextCtrl(findDialog, wx.wxID_ANY, findReplace.replaceText,  wx.wxDefaultPosition, wx.wxDefaultSize)
    end

    local findReplaceSizer = wx.wxFlexGridSizer(2, 2, 0, 0)
    findReplaceSizer:AddGrowableCol(1)
    findReplaceSizer:Add(findStatText,  0, wx.wxALL + wx.wxALIGN_LEFT, 0)
    findReplaceSizer:Add(findTextCombo, 1, wx.wxALL + wx.wxGROW + wx.wxCENTER, 0)

    if (replace) then
        findReplaceSizer:Add(replaceStatText,  0, wx.wxTOP + wx.wxALIGN_CENTER, 5)
        findReplaceSizer:Add(replaceTextCombo, 1, wx.wxTOP + wx.wxGROW + wx.wxCENTER, 5)
    end

    -- Create find/replace option checkboxes
    local wholeWordCheckBox  = wx.wxCheckBox(findDialog, wx.wxID_ANY, "Match &whole word")
    local matchCaseCheckBox  = wx.wxCheckBox(findDialog, wx.wxID_ANY, "Match &case")
    local wrapAroundCheckBox = wx.wxCheckBox(findDialog, wx.wxID_ANY, "Wrap ar&ound")
    local regexCheckBox      = wx.wxCheckBox(findDialog, wx.wxID_ANY, "Regular &expression")
    wholeWordCheckBox:SetValue(findReplace.fWholeWord)
    matchCaseCheckBox:SetValue(findReplace.fMatchCase)
    wrapAroundCheckBox:SetValue(findReplace.fWrap)
    regexCheckBox:SetValue(findReplace.fRegularExpr)

    local optionSizer = wx.wxBoxSizer(wx.wxVERTICAL, findDialog)
    optionSizer:Add(wholeWordCheckBox,  0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 3)
    optionSizer:Add(matchCaseCheckBox,  0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 3)
    optionSizer:Add(wrapAroundCheckBox, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 3)
    optionSizer:Add(regexCheckBox,      0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 3)
    local optionsSizer = wx.wxStaticBoxSizer(wx.wxVERTICAL, findDialog, "Options" );
    optionsSizer:Add(optionSizer, 0, 0, 5)

    -- Create scope radiobox
    local scopeRadioBox = wx.wxRadioBox(findDialog, wx.wxID_ANY, "Scope", wx.wxDefaultPosition, wx.wxDefaultSize,  {"&Up", "&Down"}, 1, wx.wxRA_SPECIFY_COLS)
    scopeRadioBox:SetSelection(iff(findReplace.fDown, 1, 0))
    local scopeSizer = wx.wxBoxSizer(wx.wxVERTICAL, findDialog );
    scopeSizer:Add(scopeRadioBox, 0, 0, 0)

    -- Add all the sizers to the dialog
    local optionScopeSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
    optionScopeSizer:Add(optionsSizer, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 5)
    optionScopeSizer:Add(scopeSizer,   0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 5)

    local leftSizer = wx.wxBoxSizer(wx.wxVERTICAL)
    leftSizer:Add(findReplaceSizer, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 0)
    leftSizer:Add(optionScopeSizer, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 0)

    local mainSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
    mainSizer:Add(leftSizer, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 10)
    mainSizer:Add(buttonsSizer, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 10)
    mainSizer:SetSizeHints( findDialog )
    findDialog:SetSizer(mainSizer)

    local function PrependToArray(t, s)
        if string.len(s) == 0 then return end
        for i, v in ipairs(t) do
            if v == s then
                table.remove(t, i) -- remove old copy
                break
            end
        end
        table.insert(t, 1, s)
        if #t > 15 then table.remove(t, #t) end -- keep reasonable length
    end

    local function TransferDataFromWindow()
        findReplace.fWholeWord   = wholeWordCheckBox:GetValue()
        findReplace.fMatchCase   = matchCaseCheckBox:GetValue()
        findReplace.fWrap        = wrapAroundCheckBox:GetValue()
        findReplace.fDown        = scopeRadioBox:GetSelection() == 1
        findReplace.fRegularExpr = regexCheckBox:GetValue()
        findReplace.findText     = findTextCombo:GetValue()
        PrependToArray(findReplace.findTextArray, findReplace.findText)
        if findReplace.replace then
            findReplace.replaceText = replaceTextCombo:GetValue()
            PrependToArray(findReplace.replaceTextArray, findReplace.replaceText)
        end
        return true
    end

    findDialog:Connect(ID_FIND_NEXT, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function(event)
            TransferDataFromWindow()
            findReplace:FindString()
        end)

    findDialog:Connect(ID_REPLACE, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function(event)
            TransferDataFromWindow()
            event:Skip()
            if findReplace.replace then
                ReplaceString()
            else
                findReplace.dialog:Destroy()
                findReplace.dialog = CreateFindReplaceDialog(true)
                findReplace.dialog:Show(true)
            end
        end)

    if replace then
        findDialog:Connect(ID_REPLACE_ALL, wx.wxEVT_COMMAND_BUTTON_CLICKED,
            function(event)
                TransferDataFromWindow()
                event:Skip()
                ReplaceString(true)
            end)
    end

    findDialog:Connect(wx.wxID_ANY, wx.wxEVT_CLOSE_WINDOW,
        function (event)
            TransferDataFromWindow()
            event:Skip()
            findDialog:Show(false)
            findDialog:Destroy()
        end)

    return findDialog
end

function findReplace:Show(replace)
    self.dialog = nil
    self.dialog = CreateFindReplaceDialog(replace)
    self.dialog:Show(true)
end



------------------------------------------------------------------------------------------
--          file sys
------------------------------------------------------------------------------------------

function LoadFile(filePath,  file_must_exist)
    local file_text = ""
    local handle = io.open(filePath, "rb")
    if handle then
        file_text = handle:read("*a")
        handle:close()
    elseif file_must_exist then
        return nil
    end

    editor:Clear()
    editor:ClearAll()
    editor:AppendText(file_text)
    editor:EmptyUndoBuffer()

    appDocument.filePath = filePath
    appDocument.fileName = wx.wxFileName(filePath):GetFullName()
    appDocument.modTime = GetFileModTime(filePath)
    appDocument.isModified = false

    return true
end

function OpenFile()
    local fileDialog = wx.wxFileDialog(frame, "Open file","","", "All files (*)|*",
              wx.wxOPEN + wx.wxFILE_MUST_EXIST)
    if fileDialog:ShowModal() == wx.wxID_OK then
        if not LoadFile(fileDialog:GetPath(), true) then
            wx.wxMessageBox("Unable to load file '"..fileDialog:GetPath().."'.",
             "Error Loading",wx.wxOK + wx.wxCENTRE, frame)
        else
            frame:SetTitle(fileDialog:GetPath())
        end
    end
    fileDialog:Destroy()
end


function SaveFile(filePath)
    if filePath == "" then
        return SaveFileAs(editor)
    else

        local backPath = filePath..".bak"
        os.remove(backPath)
        os.rename(filePath, backPath)

        local handle = io.open(filePath, "wb")
        if handle then
            local st = editor:GetText()
            handle:write(st)
            handle:close()
            ----editor:EmptyUndoBuffer()  --I hate when they do that
            appDocument.filePath = filePath
            appDocument.fileName = wx.wxFileName(filePath):GetFullName()
            appDocument.modTime = GetFileModTime(filePath)
            appDocument.isModified = false

            return true
        else
            wx.wxMessageBox("Unable to save file '"..filePath.."'.",
                            "Error Saving",
                            wx.wxOK + wx.wxCENTRE, frame)
        end
    end

    return false
end


function SaveFileAs()
    local saved    = false
    local fn       = wx.wxFileName(appDocument.filePath)
    fn:Normalize() -- want absolute path for dialog

    local fileDialog = wx.wxFileDialog(frame, "Save file as",
                                    fn:GetPath(),
                                    fn:GetFullName(),
                                    "All files (*)|*",
                                    wx.wxSAVE)

    if fileDialog:ShowModal() == wx.wxID_OK then
        local filePath = fileDialog:GetPath()

        if SaveFile(filePath) then
            saved = true
            frame:SetTitle(filePath)
        end
    end

    fileDialog:Destroy()
    return saved
end


function SaveOnExit()
    local result   = wx.wxID_NO
    local filePath = appDocument.filePath
    local fileName = appDocument.fileName

    if appDocument.isModified then
        local message
        if fileName ~= "" then
            message = "Save changes to '"..fileName.."' before exiting?"
        else
            message = "Save changes to 'untitled' before exiting?"
        end
        local dlg_styles = wx.wxYES_NO + wx.wxCENTRE + wx.wxICON_QUESTION

        local dialog = wx.wxMessageDialog(frame, message,"Save Changes?",dlg_styles)
        result = dialog:ShowModal()
        dialog:Destroy()
        if result == wx.wxID_YES then
            SaveFile(filePath)
        end
    end
end



------------------------------------------------------------------------------------------
--         view
------------------------------------------------------------------------------------------

function Wrap()
    if editor:GetWrapMode() == 1 then
        editor:SetWrapMode(0)
    else
        editor:SetWrapMode(1)
    end
end



function Fold(show)
    local ss = ""
    for line=0, editor.LineCount-1 do
        local p = editor:GetFoldParent(line)
        if p ~= -1 then
            if show then
                  if not editor:GetFoldExpanded(p) then  editor:ToggleFold(p) end
            else
                if editor:GetFoldExpanded(p) then  editor:ToggleFold(p) end
            end
        end
    end
end

------------------------------------------------------------------------------------------
--         help
------------------------------------------------------------------------------------------

function About()
    local dialog = wx.wxMessageDialog(frame, 
                        appName.." is a simple editor for markup languages developed with wxLua.",
                        "About",
                        wx.wxOK)
    result = dialog:ShowModal()
    dialog:Destroy()
end


------------------------------------------------------------------------------------------
--          init
------------------------------------------------------------------------------------------



frame:Connect(ID_NEW, wx.wxEVT_COMMAND_MENU_SELECTED, function(event) run(appFile) end)
frame:Connect(ID_OPEN, wx.wxEVT_COMMAND_MENU_SELECTED, function(event)  OpenFile() end)
frame:Connect(ID_SAVE, wx.wxEVT_COMMAND_MENU_SELECTED,function(event)  SaveFile(appDocument.filePath) end)
frame:Connect(ID_SAVEAS, wx.wxEVT_COMMAND_MENU_SELECTED,function(event) SaveFileAs() end)
frame:Connect(ID_BROWSE, wx.wxEVT_COMMAND_MENU_SELECTED,function(event) wx.wxLaunchDefaultBrowser(appDocument.filePath) end)
frame:Connect(ID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED, function(event)   frame:Close()  end)
frame:Connect(ID_CUT, wx.wxEVT_COMMAND_MENU_SELECTED, function(event)  editor:Cut() end)
frame:Connect(ID_COPY, wx.wxEVT_COMMAND_MENU_SELECTED, function(event)  editor:Copy() end)
frame:Connect(ID_PASTE, wx.wxEVT_COMMAND_MENU_SELECTED, function(event) editor:Paste() end)
frame:Connect(ID_DELETE, wx.wxEVT_COMMAND_MENU_SELECTED, function(event) editor:Clear() end)
frame:Connect(ID_SELECTALL, wx.wxEVT_COMMAND_MENU_SELECTED, function(event) editor:SelectAll() end)
frame:Connect(ID_FIND, wx.wxEVT_COMMAND_MENU_SELECTED, function (event) findReplace:Show(false) end)
frame:Connect(ID_REPLACE, wx.wxEVT_COMMAND_MENU_SELECTED,  function (event) findReplace:Show(true) end)
frame:Connect(ID_UPPER, wx.wxEVT_COMMAND_MENU_SELECTED, function(event)  editor:UpperCase() end)
frame:Connect(ID_LOWER, wx.wxEVT_COMMAND_MENU_SELECTED, function(event) editor:LowerCase() end)
frame:Connect(ID_INDENT, wx.wxEVT_COMMAND_MENU_SELECTED, function(event)  editor:Tab() end)
frame:Connect(ID_UNINDENT, wx.wxEVT_COMMAND_MENU_SELECTED, function(event) editor:BackTab() end)
frame:Connect(ID_UNDO, wx.wxEVT_COMMAND_MENU_SELECTED, function(event)  editor:Undo() end)
frame:Connect(ID_REDO, wx.wxEVT_COMMAND_MENU_SELECTED, function(event) editor:Redo() end)
frame:Connect(ID_WRAP, wx.wxEVT_COMMAND_MENU_SELECTED, function(event)  Wrap() end)
frame:Connect(ID_FOLD, wx.wxEVT_COMMAND_MENU_SELECTED, function(event) Fold(false) end)
frame:Connect(ID_UNFOLD, wx.wxEVT_COMMAND_MENU_SELECTED, function(event) Fold(true)  end)
frame:Connect(ID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED, function(event)  About() end)
frame:Connect(wx.wxEVT_CLOSE_WINDOW, function(event)   SaveOnExit();   event:Skip() end)

menu=CreateMenu()
editor=CreateEditor()
frame:Show(true)
--wx.wxGetApp():MainLoop()

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.


