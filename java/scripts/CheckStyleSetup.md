Using a variation of:
--------------
    https://github.com/checkstyle/checkstyle/blob/master/src/main/resources/google_checks.xml
    commit 8c0e35daa02c71c5077053f607c36e10ab07717e 

Modifications:

    * Some google_checks.xml tokens were removed as they are not compatible with maven versions of CheckStyle
    * Changed Max lines is 120 (default for IntelliJ IDEA), from 100
    * Changed to 4 Spaces for most indents, from 2
--

The following process will enable CheckStyle in the IDE

Setup Part 1:
--------------

* Install JavaDoc plugin
* Install CheckStyle-IDEA plugin
* Restart IDE.
(there are IDE changes below to keep code compatible with checkstyle)
* IntelliJ IDEA -> preferences -> search 'binary' -> Binary Expressions - operation sign on next line - uncheck
* IntelliJ IDEA -> preferences -> search 'code style' -> Java ->
    Tabs and Indents -> Tab Size 4, Indent 4, Continuation Indent 4
* IntelliJ IDEA -> preferences -> Editor -> Code Style
    Scheme (hit gear icon to the right) -> Import Scheme -> CheckStyle Configuration
    Browse to google_checks.xml, Hit OK

Setup Part 2:
--------------

* IntelliJ IDEA -> preferences -> search 'checkstyle'

* CheckStyle Version -> 10.1
* Treat Checkstyle errors as warnings - check
* Only Java sources (but not tests)
* Under Configuration File 
    - Add (+)
    - Name: Google CheckStyle BBY
    - Browse to file: scripts/checkstyle/google_checks.xml
    - Hit OK

* Check Google CheckStyle BBY line item

* Hit APPLY, then OK

3 Scenarios Supported:
--------------

1. Realtime editing:
    Open any file and see yellow warnings for Checkstyle violations.

2. On demand CheckStyle scan:
    There should be a CheckStyle tab along the bottom tab bar (around Run, Problems, Build, Terminal, etc.)
    Rules: Google CheckStyle BBY
    Click Folder with tiny black square in corner. This is a project scan.

3. Maven error on CheckStyle violation
   To return the violations as a list for each module:
   Run: mvn checkstyle:check  

Shortcuts
---------------
Shift+Option+Command+G - creates DocBlock for file with cursor. Can be delayed sometimes. Practice using it.
Option+Command+L - fixes many CheckStyle formatting problems (not all)
