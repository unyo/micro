require "sinatra"
require "haml"
require "sass"
require "coffee-script"
require "sinatra/reloader"

set :bind, "0.0.0.0"

get "/" do
    @intro = "
    "
    haml :index
end

get "/style.css" do
    sass :style
end

get "/editor.js" do
    coffee :editor
end

get "/ls" do
    Dir[File.join('./', '**', '*')]
end

get "/edit/:filename" do
    @filename = params[:filename]
    haml :edit
end

get "/file/intro" do
    erb :intro, :layout => false
end

get "/file/:filename" do
    halt 404 unless File.file?(params[:filename])
    stream do |out|
        File.foreach(params[:filename]) do |line|
            out << line
        end
    end
end

post "/file/:filename" do
    File.write(params[:filename], params[:data])
end

__END__

@@index
%textarea.edit-area{data: {filename: "intro"}}

@@edit
%textarea.edit-area{data: {filename: "#{@filename}"}}

@@layout
!!! 5
%html
    %head
        %title
            In-browser Editor
        %link{rel: "stylesheet", href: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/codemirror.css"}
        %link{rel: "stylesheet", href: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/theme/zenburn.css"}
        %link{rel: "stylesheet", href: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/addon/fold/foldgutter.css"}
        %link{rel: "stylesheet", href: "/style.css"}
    %body
        = yield
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/codemirror.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/mode/xml/xml.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/mode/css/css.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/mode/javascript/javascript.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/mode/ruby/ruby.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/mode/python/python.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/mode/htmlmixed/htmlmixed.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/mode/sass/sass.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/mode/coffeescript/coffeescript.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/mode/haml/haml.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/addon/runmode/colorize.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/addon/fold/foldcode.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/addon/fold/foldgutter.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/addon/fold/indent-fold.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/addon/fold/xml-fold.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/addon/fold/brace-fold.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/addon/fold/comment-fold.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/zepto/1.1.4/zepto.js"}
    %script{src: "/editor.js"}

@@style
body
    margin: 0
.edit-area, .CodeMirror
    width: 100vw
    height: 100vh
    box-sizing: border-box

@@editor
console.log "starting editor"
edit_area = $('.edit-area')[0]
options = 
    theme: "zenburn"
    mode: "htmlmixed"
    autofocus: true
    indentUnit: 4
    lineNumbers: true
    foldGutter: true
    gutters: ["CodeMirror-foldgutter", "CodeMirror-linenumbers"]
filename = $(edit_area).data 'filename'
if filename
    if filename.indexOf('.rb') > 0
        options.mode = "ruby"
    if filename.indexOf('.python') > 0
        options.mode = "python"
    if filename.indexOf('.html') > 0
        options.mode = "htmlmixed"
    if filename.indexOf('.js') > 0
        options.mode = "javascript"
    if filename.indexOf('.css') > 0
        options.mode = 'css'
    if filename.indexOf('.sass') > 0
        option.mode = 'sass'
    if filename.indexOf('haml') > 0
        option.mode = 'haml'
    if filename.indexOf('xml') > 0
        option.mode = 'xml'
    $(edit_area).load '/file/'+filename, ->
        editor = CodeMirror.fromTextArea edit_area, options
else
    editor = CodeMirror.fromTextArea edit_area, options

@@intro
In-Browser Editor v0.1 - a single file in-browser IDE

Usage: ruby micro.rb
Description:
    A in-browser editor that you can use to edit 
    source code files on the fly. Simply download
    the ruby file and run within a directory you
    want to serve. Great for Chromebook web devs.
Todo:
    - Saving
    - Pressing 'CTRL' brings up image with hotkeys
    - Pressing 'CTRL-m' or something lets you 
      remap hotkeys
    - Add vi mode hotkey 
