GLEN KEANE - 20057974

A simple ruby command line application that demonstrates serverside caching and local application caching. 
All running applications have a local cache, and they receive their local data from a cache server (memcached) and a database (sqlite).

Gems required to run:
	Dalli
	Sequel

Command to run application is: ruby driver.rb ./db/bookShop.sqlite

Marking breakdown:
Pass (40-50%) - Completed
Good (50-65%) - Completed
Excellent (65-85%) – Completed
Outstanding (85-100%) – Everything except eviction policy on local cache - stale data is removed when made stale LOCALLY or detected to be stale from another source, no ttl on data/max amount of data that can be stored.


NOTES:

All stale data in caches is deleted when neccessary. 

Every time a person accesses the local cache, they must check it matches the shared cache.
When searching, the application will always check to see if there is any data in the database that is not in the shared cached or local cache.

Examples of possible issues and how the application deals wth them:

Two people(p1 and p2) are running the application from seperate locations, and there are 3 entries by author X in the DB: e1, e2, and e3.
P1 updates e1, so now his local cache has e1 and the shared cache has e1.
P2 updates e2, so now his local cache has e2 and the shared cache has e1 AND e2.
P1 does an author search for x, gets e1 from local cache, e1 and e2 from shared cache, and e1, e2 and e3 from database.
the application combines all these and adds e2 and e3 to the local cache, and adds e3 to the shared cache.
e1 is deleted from the shared cache after it times out.
P2 does a search and the application still must then dial back to the database to see if there is any entities missing from the shared cache result.

Therefore, a database call must be done on all searchs. 

Also, to add on to the previous scenario:
P2 deletes e2. (deleted from P2's local cache, the shared cache and the database.)
P1 searches for e2's isbn:
e2 is in P1 local cache, does its version match shared cache? No.
It must check if e2 is in the database to see if e2 just timed out of the shared cache or was deleted.

EVEN WHEN selecting data from the local cache, a database call is neccessary to see if the cached result has been deleted.