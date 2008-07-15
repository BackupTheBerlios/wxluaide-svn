package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;lib/?.dll;/usr/local/luaaio/lib/?.so"
require 'lib/luasqlite3'

db = sqlite3.open("cbrowser.db3")

db:exec[[ 
    create table project ( name, autoload, data);
    create table package ( package,class, code);
    create table settings (name, settings);
    insert into project (name,autoload,data) values ('browser',1,'');
    insert into project (name,autoload,data) values ('ide',0,'');
 ]]
 
 db:close()