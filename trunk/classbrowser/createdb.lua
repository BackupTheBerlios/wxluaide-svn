package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;lib/?.dll;/usr/local/luaaio/lib/?.so"
require 'lib/luasqlite3'

db = sqlite3.open("cbrowser.db3")

db:exec[[ 
    create table project (id, name, baseDir,srcDir,classes,srcFiles,packages,type);
    create table package (id, projectid, package,code);
	create table settings (id, settings);
 
 ]]