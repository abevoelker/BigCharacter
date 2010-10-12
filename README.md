BigCharacter
==========================

What is this?
--------------
BigCharacter is an attempt at creating a useful new datatype in Progress OpenEdge ABL.  It is essentially meant to be an alternative to LONGCHAR, attempting to overcome some of its shortcomings in the process (the main one being to not have a performance penalty when appending CHARACTER data to it).

How to use it
--------------
* You will need to add the `com/abevoelker` path to your `PROPATH`.  Otherwise, Progress won't understand what the object references mean.

Errata
-------
* This is a work-in-progress that I would not consider safe for production use.

License
--------
BigCharacter is released under the [LGPLv2.1][licensesite] or greater license.

[licensesite]: http://github.com/abevoelker/BigCharacter/blob/master/LICENSE

