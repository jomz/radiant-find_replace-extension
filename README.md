# Find Replace

This extension adds find and replace functionality to the backend of your Radiant CMS based website.

Supports regular expressions and case (in)sensitivity.
When showing results, you can check which matches you want to update with the replace string.
If you are using regular expressions, you can render matches in the replace string. For example, find:

    <p class="title">([^</p>]*)</p>

Replace:

    <h2>\1</h2>

The results page does not show the actual results, but the pages, snippets and layouts that had at least one match. 
All the more reason to be very careful when you use the replace functionality, especially when you are using regular expressions.

Created by Benny Degezelle.