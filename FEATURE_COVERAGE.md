## Overview

The end goal of the project is to provide 100% of the functionality of UIKit*.  Currently, we are covering about 40%**. This page provides the current status of the work. 



*unless nobody wants the last 10%
** explain how this is measured and provide real value
the 

### What functionalities are available? 
 
Our [test app]() will give you a nice overview and demonstration. For details, see the tables below - there is a table for every UIKit class that we cover. The table shows the status of our work on a all elements (properties and methods) of that class. If there is no table, that means we’re not implementing that class at all (yet).


### How to request a functionality to be covered?

If you don't see what you're looking for (or you see that it's not available), search our issues for it (using Apple's naming). If you find it there, please 'upvote' the existing issue with a "👍". If you don’t find it there, please open a new issue, adhering to our naming policy (see below).


### Naming policy for new feature requests

To add an issue that requests a new feature (class, property or method), add appropriate `tags` to your issue and state the "class - element" in the title, using Apple's naming. Examples:

`class request` **UITextView** - if you're requesting the [UITextView](https://developer.apple.com/documentation/uikit/uitextview) class to be added 

`method request` **UILabel - drawText(in:)** - if you're requesting the [drawText(in:) method from the UILabel class](https://developer.apple.com/documentation/uikit/uilabel/1620527-drawtext?changes=_2) to be added

You do not need to provide any additional information in the issue description, but explaining why this element is important for you will always be welcome, as it helps us prioritize.


## Functionality availability table 

### [UILabel](https://developer.apple.com/documentation/uikit/uilabel?changes=_2#topics)
| Type  | Name           | Requested | Implemented | Test coverage |
|-------|----------------|:---------:|:-----------:|:-------------:|
|   var | text           |     ✅     |      ✅      |       ✅      |
|   var | attributedText |     ✅     |      ✅      |       ✅       |
| func  | draw()         |     ✅     |      ✅      |               |
|   fun | drawText(in:)  |     ✅     |             |               |
