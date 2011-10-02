AutoHotkey.net Website Generator
================================
Generates a website automatically using information gathered from the [AutoHotkey Forums].

Example
-------

Here are some examples of websites generated by this program:

* http://www.autohotkey.net/~Uberi/
* http://www.autohotkey.net/~maul.esel/
* http://www.autohotkey.net/~frankie/
* http://www.autohotkey.net/~sumon/
* http://www.autohotkey.net/~tomoe_uehara/

And here are some sites people have built based on the generated pages:

* http://www.autohotkey.net/~aaronbewza/
* http://www.autohotkey.net/~shajul/

Usage
-----

AutoHotkey.net Website Generator supports configuration through either variables at the top of the main script, through command line parameters, or through a GUI.

### Variable configuration

Setting the variables at the top of the main script, "GeneratePage.ahk", will affect how the script works if it is run without any other configuration. This may be useful when one desires to schedule website updates automatically or on a schedule. However, command line configuration may be more appropriate in some cases.

### Command line configuration

Command line parameters override the variables set at the top of the main script. Parameter names mirror the names of the aforementioned variables:

    GenerateWebsite.ahk --ShowGUI=False --ForumUsername=Uberi --UploadWebsite=True --AutoHotkeyNetPassword=MyPassword --ColorScheme=Blue

The above would silently generate a page for the user "Uberi" at the AutoHotkey Forums with a blue color scheme, and then upload it to AutoHotkey.net over FTP.

### GUI configuration

A configuration GUI will be shown if the "ShowGUI" option is set.

Options
-------

### Credentials
* _ForumUsername_ - The forum username to generate the website for.
* _AutoHotkeyNetUsername_ - The AutoHotkey.net account username. Leave blank if it is the same as the forum username.
* _AutoHotkeyNetPassword_ - The AutoHotkey.net account password. Necessary only if _UploadWebsite_ is set.

### Behavior
* _ShowGUI_ - Show the configuration GUI on startup.
* _UploadWebsite_ - Upload the website to AutoHotkey.net after it has been generated.
* _SearchEnglishForum_ - Search the English AutoHotkey Forums for posts.
* _SearchGermanForum_ - Search the German AutoHotkey Forums for posts.
* _UseCache_ - Use the information cache to avoid downloading unnecessary data.

### Appearance
* _Stylesheet_ - The stylesheet to use for the generated website, without the ".css" extension.
* _SortPages_ - Whether or not to sort the website entries alphabetically. If not set, the script will sort by the time of the last update.

### Output
* _OutputDirectory_ - The local directory to save the generated website.
* _InlineCSS_ - Inline the CSS stylesheet within the HTML page. Useful for making websites self contained.
* _RelativeLinks_ - Rewrite links to make them relative to the webpage if possible.
* _DownloadResources_ - Download resources such as scripts and images to the website directory, to make the generated website self contained.

[AutoHotkey Forums]: http://www.autohotkey.com/forum/