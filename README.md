# <img src="https://www.koozali.org/images/koozali/Logo/Png/Koozali_logo_2016.png" width="25%" vertical="auto" style="vertical-align:bottom"> smeserver-migratehelper

SMEServer Koozali developed git repo for smeserver-migratehelper smecontribs

## Wiki
<br />https://wiki.koozali.org/Migratehelper
<br />https://wiki.koozali.org/Migratehelper/fr

## Bugzilla
Show list of outstanding bugs:
[All](https://bugs.koozali.org/buglist.cgi?action=wrap&bug_status=UNCONFIRMED&bug_status=CONFIRMED&bug_status=NEEDINFO&bug_status=IN_PROGRESS&bug_status=RESOLVED&bug_status=VERIFIED&classification=Contribs&component=smeserver-migratehelper&list_id=105781&order=changeddate+DESC%2Ccomponent%2Cpriority%2Cbug_severity&product=SME+Contribs&query_format=advanced)  
[Confirmed](https://bugs.koozali.org/buglist.cgi?action=wrap&bug_status=CONFIRMED&classification=Contribs&component=smeserver-migratehelper&list_id=105781&order=changeddate+DESC%2Ccomponent%2Cpriority%2Cbug_severity&product=SME+Contribs&query_format=advanced)  
[Unconfirmed](https://bugs.koozali.org/buglist.cgi?action=wrap&bug_status=UNCONFIRMED&classification=Contribs&component=smeserver-migratehelper&list_id=105781&order=changeddate+DESC%2Ccomponent%2Cpriority%2Cbug_severity&product=SME+Contribs&query_format=advanced)  
[Need Info](https://bugs.koozali.org/buglist.cgi?action=wrap&bug_status=NEEDINFO&classification=Contribs&component=smeserver-migratehelper&list_id=105781&order=changeddate+DESC%2Ccomponent%2Cpriority%2Cbug_severity&product=SME+Contribs&query_format=advanced)  
[In Progress](https://bugs.koozali.org/buglist.cgi?action=wrap&bug_status=IN_PROGRESS&classification=Contribs&component=smeserver-migratehelper&list_id=105781&order=changeddate+DESC%2Ccomponent%2Cpriority%2Cbug_severity&product=SME+Contribs&query_format=advanced)  
[Verified](https://bugs.koozali.org/buglist.cgi?action=wrap&bug_status=VERIFIED&classification=Contribs&component=smeserver-migratehelper&list_id=105781&order=changeddate+DESC%2Ccomponent%2Cpriority%2Cbug_severity&product=SME+Contribs&query_format=advanced)  
[Resolved](https://bugs.koozali.org/buglist.cgi?action=wrap&bug_status=RESOLVED&classification=Contribs&component=smeserver-migratehelper&list_id=105781&order=changeddate+DESC%2Ccomponent%2Cpriority%2Cbug_severity&product=SME+Contribs&query_format=advanced)  

## Description

was created to help backup contribs, and only backup config without the big amount of data that could be restored later from ssh or moving a dedicated drive. 


perl -Mesmith::Backup -e 'my @list=esmith::Backup->excludes(); print map "/$_\n", @list;;'

perl -Mesmith::Backup -e 'my @list=esmith::Backup->restore_list(); print map "/$_\n", @list;;'
