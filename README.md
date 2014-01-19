
MMShowcase Magazine framework
Readme File
================================================================================

Contents:
--------------------

I.	Copyright notice
II.	Introduction
III.	Requirements
IV.	Notes

--------------------

I.	Copyright notice

This software is copyright (C)2010 / 2011 Joost Verrijt and Metamotifs. 
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

* Neither the name of the project's author nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


--------------------

II.	Introduction

Example Magazine Application inspired by Flipboard.

It uses one main XML file (see magazine.xml) that defines the content of a magazine. 
It supports so-called side-controllers which can hold content such as context sensitive 
Twitter messages and a table of contents, both of these side controllers are included
in this release.

Overlays are views that sit on top of a magazine page and display various
contextual information. A simple overlay controller is included that views links inside 
of a web browser.

--------------------

III.	Requirements

* iOS 4+ SDK 
* Lib XML 2

This software depends on and acknowledges the following third-party libraries: 

* TouchXML
* Google Toolbox for Mac (GTM)
* SBJson framework

--------------------

IV.	Notes

* There is currently no built-in way to switch from landscape (the default orientation) to 
portrait. For the PageViewController, which has a complex view hierarchy, a portrait 
version is provided. 

* The PageViewController consists of several views that are essential for creating the
page turning effect. The main layer holds: 

1. Page Turn Container
Contains a left and right 'leaf' image, During page turning, this is the layer that is animated
like a revolving door. The FX layer darkens the page during turn.

2. Main page container 
Holds the images for both 'leaves'. When a page turn is done, the appropriate leaves are shuffled 
around during animation to transition to the new page. The imageBuffer view is currently only
used to blend in the overlay view with the full page and might be removed in future releases.

3. fxBookShadow
Holds an image that simulates the shadow that is cast by a turning page.

4. Overlay Container
This view holds the views for any overlays.
