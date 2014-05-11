------------------------------------------------------------
 Online manual: http://ccv.sourceforge.net
------------------------------------------------------------



================================================================================
Abbreviation
CCV = Code(cvs/svn) Change Viewer
FOC = File of change
LOC = Line of change)

================================================================================
* Features
ccv supply unify solution to stat./get/browse cvs/svn module code change

- can get LOC/FOC, check-in comments, code diff
- user can upload customized cvs/svn module config file to server.
- feature details, it supports two report modes.
   - base on cvs/svn log, can get
       - module's all acounts check-in information
       - code diff of every check-in
       - cvs/svn check in comment/LOC/FOC group by module/acount/file
       - check-in times on a file
   - base on cvs/svn diff, can get 
       - exact FOC/LOC group by directory/module between two revisions/dates
       - code diff of each file
       - tree or flat view report
- ccv behavior as web service tool, easy access & usage, 
   and it also suppot shell command line mode.
- ccv can stat. one or more cvs/svn modules one time.
- ccv can stat. repository module source file composition info
- ccv has easy-use install/upgrade/remove feature.
- ccv suports online-upgrade.
       
================================================================================  
* Env requirement: linux + apache + perl + cvs + svn
- linux/unix-like os	
  All POSIX (linux/BSD/unix-like OSes)
  
- apache
  it server does not include it, pls install it 
    
- perl
  it is a standard package in almost all linux distributions. 
  If you can run "perl" commnad, then it is OK,
  and"perl -v" command will show perl version.
    
- cvs
  almost all linux distributions include it.
  if you linux server can run "cvs" command, then OK
  
- svn
  almost all linux distributions include it.
  if you linux server can run "svn" command, then OK, 
  if not, please install it first.  

================================================================================
* Install 
1. switch to root
2. tar -xzvf ccv-2.0-%date%.tar.gz
   following files will be extracted
   |--INSTALL.pl
   |--ccv.tar.gz
   |--README
   
3. run "perl INSTALL.pl --apache-conf=/path/of/httpd.conf --prefix=/install/ccv/to"
   Example:
       perl INSTALL.pl --help
       perl INSTALL.pl --apache-conf=/usr/local/apache2/conf/httpd.conf --prefix=/usr/local

   INSTALL.pl script will do:
       1). ccv will locate at /usr/local/ccv
       2). INSTALL.pl modify httpd.conf, add include statement to get ccv CGI definition
           file: httpd.conf
           ...
           include /usr/local/ccv/config/ccv.script.alias.httpd
           ...
       3). get httpd configure "DocumentRoot"
           ln -s /usr/local/ccv/web/ /%DcoumentRoot%/ccv

4. restart apache
   
   after INSTALL.pl finished,
   you need to customize your modules by accessing http://server_ip/ccv/ccv.html 

================================================================================   
* ccv entry URL: http://server_ip/ccv/ccv.html
* ccv manual: http://server_ip/ccv/manual.html



------------------------------------------------------------
 Online manual: http://ccv.sourceforge.net
------------------------------------------------------------
