# Coffee Stirrer

Coffee Stirrer is a coffee script pre processor that allows the user to use <code>#=include <file> </code> in their scripts.  
The file can be a local file present in a folder or a remote file.  

Both CSS, Javascript and Coffeescript files are allowed for inclusion. 


# Usage

Coffee-Stirrer supports compilation and watching over files.  

To compile a coffee script file (e.g. afile.coffee) to a folder (e.g. output) and include a libraries directory (e.g. ./libs) use

    coffee coffeescript-stirrer.coffee -c -I ../libs --output ./output afile.coffee

To watch  a coffee script file (e.g. afile.coffee) to a folder (e.g. output) and include a libraries directory (e.g. ./libs) use

    coffee coffeescript-stirrer.coffee -w -c -I ../libs --output ./output afile.coffee


# Example 

## Local
Including jQuery from the libs Folder to a file acoffee.coffee and output the compiled class in ./output.  

### acoffee.coffee
    #=include <jquery-1.7.2.min.js>
  
    $(document).ready(( ->
        console.log "Hello World"
    )) 
  
Compile the code with the following command. 
    
    coffee coffeescript-stirrer.coffee -c -I ../libs --output ./output afile.coffee
    

## Remote
Including jQuery (https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js) to a file acoffee.coffee and output the compiled class in ./output.  

### acoffee.coffee

    #=include <https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js>

    $(document).ready(( ->
        console.log "Hello World"
    ))

Compile the code with the following command. 
    
    coffee coffeescript-stirrer.coffee -c --output ./output afile.coffee
    
    
Including JQuery UI CSS (https://ajax.googleapis.com/ajax/libs/jqueryui/1.8/themes/base/jquery.ui.all.css) to a file acoffee.coffee and output the compiled class in ./output. Note that CSS can only be remote.  

### acoffee.coffee

    #= include <https://ajax.googleapis.com/ajax/libs/jqueryui/1.8/themes/base/jquery.ui.all.css>
    
    $(document).ready(( ->
        console.log "Hello World"
    ))

    
# FAQ
* I am seeing the error "Cannot find module 'coffee-script'"
  
  Please export the NODE_PATH variable.  export NODE_PATH=$NODE_PATH:<path>/homebrew/lib/node_modules/






