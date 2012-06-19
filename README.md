Coffee Stirrer
==============

Coffee Stirrer is a coffee script pre processor that allows the user to use <code>#=include <file> </code> in their scripts.  
The file can be a local file present in a folder or a remote file.  

Both Javascript and Coffeescript files are allowed for inclusion. 

This project was inspired by https://github.com/fairfieldt/coffeescript-concat and awesome script that allows concatenation of coffee script files.   


Usage
=====
Coffee-Stirrer supports compilation and watching over files.  

To compile a coffee script file (e.g. afile.coffee) to a folder (e.g. output) and include a libraries directory (e.g. ./libs) use

<code>coffee coffeescript-stirrer.coffee -c -I ../libs --output ./output afile.coffee</code>

To watch  a coffee script file (e.g. afile.coffee) to a folder (e.g. output) and include a libraries directory (e.g. ./libs) use

<code>coffee coffeescript-stirrer.coffee -w -c -I ../libs --output ./output afile.coffee</code>


Local Example 
=============
Including jQuery from the libs Folder to a file acoffee.coffee and output the compiled class in ./output.  

acoffee.coffee
  <code>  
  #=include <jquery-1.7.2.min.js>
  
  $(document).ready(( ->
    console.log "Hello World"
  )) 
  </code>


  <code>coffee coffeescript-stirrer.coffee -c -I ../libs --output ./output afile.coffee</code>

Remote Example 
=============
Including jQuery (https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js) to a file acoffee.coffee and output the compiled class in ./output.  

acoffee.coffee

  <code>
  #=include <https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js>

  $(document).ready(( ->
    console.log "Hello World"
  ))
  </code>


  <code>coffee coffeescript-stirrer.coffee -c --output ./output afile.coffee</code>






